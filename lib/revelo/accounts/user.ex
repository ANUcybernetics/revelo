defmodule Revelo.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Accounts,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication],
    data_layer: AshPostgres.DataLayer

  alias AshAuthentication.Strategy.Password.HashPasswordChange
  alias AshAuthentication.Strategy.Password.PasswordConfirmationValidation

  authentication do
    tokens do
      enabled? true
      token_resource Revelo.Accounts.Token
      signing_secret Revelo.Secrets
      store_all_tokens? true
    end

    strategies do
      password :password do
        identity_field :email

        resettable do
          sender Revelo.Accounts.User.Senders.SendPasswordResetEmail
          # these configurations will be the default in a future release
          password_reset_action_name :reset_password_with_token
          request_password_reset_action_name :request_password_reset_token
        end
      end
    end

    add_ons do
      confirmation :confirm_new_user do
        monitor_fields [:email]
        confirm_on_create? true
        confirm_on_update? false

        auto_confirm_actions [
          :sign_in_with_magic_link,
          :reset_password_with_token,
          :register_anonymous_user
        ]

        sender Revelo.Accounts.User.Senders.SendNewUserConfirmationEmail
      end
    end
  end

  postgres do
    table "users"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    create :register_anonymous_user do
      change Revelo.Accounts.Changes.GenerateAnonymousTokenChange

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    update :upgrade_anonymous_user do
      description "Upgrade an anonymous user to a full user with email and password."

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      change set_attribute(:email, arg(:email))
      change HashPasswordChange
      validate PasswordConfirmationValidation
      change AshAuthentication.GenerateTokenChange
    end

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    update :change_password do
      require_atomic? false
      accept []
      argument :current_password, :string, sensitive?: true, allow_nil?: false
      argument :password, :string, sensitive?: true, allow_nil?: false
      argument :password_confirmation, :string, sensitive?: true, allow_nil?: false

      validate confirm(:password, :password_confirmation)

      validate {AshAuthentication.Strategy.Password.PasswordValidation,
                strategy_name: :password, password_argument: :current_password}

      change {HashPasswordChange, strategy_name: :password}
    end

    read :sign_in_with_password do
      description "Attempt to sign in using a email and password."
      get? true

      argument :email, :ci_string do
        description "The email to use for retrieving the user."
        allow_nil? false
      end

      argument :password, :string do
        description "The password to check for the matching user."
        allow_nil? false
        sensitive? true
      end

      prepare AshAuthentication.Strategy.Password.SignInPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    read :sign_in_with_token do
      description "Attempt to sign in using a short-lived sign in token."
      get? true

      argument :token, :string do
        description "The short-lived sign in token."
        allow_nil? false
        sensitive? true
      end

      prepare AshAuthentication.Strategy.Password.SignInWithTokenPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    create :register_with_password do
      description "Register a new user with a email and password."

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      change set_attribute(:email, arg(:email))
      change HashPasswordChange
      change AshAuthentication.GenerateTokenChange
      validate PasswordConfirmationValidation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    action :request_password_reset_token do
      description "Send password reset instructions to a user if they exist."

      argument :email, :ci_string do
        allow_nil? false
      end

      run {AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email}
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get? true

      argument :email, :ci_string do
        allow_nil? false
      end

      filter expr(email == ^arg(:email))
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      validate AshAuthentication.Strategy.Password.ResetTokenValidation
      validate PasswordConfirmationValidation
      change HashPasswordChange
      change AshAuthentication.GenerateTokenChange
    end

    update :promote_to_admin do
      accept []
      change set_attribute(:admin, true)
      validate changing(:admin)
    end

    update :demote_to_regular_user do
      accept []
      change set_attribute(:admin, false)
      validate changing(:admin)
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy always() do
      forbid_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? true
      public? true
    end

    attribute :admin, :boolean, default: false

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end
  end

  calculations do
    calculate :facilitator?, :boolean do
      argument :session_id, :uuid do
        allow_nil? false
      end

      calculation fn users, context ->
        Enum.map(users, fn user ->
          participant =
            Ash.get!(Revelo.Sessions.SessionParticipants,
              session_id: context.arguments.session_id,
              participant_id: user.id
            )

          participant.facilitator?
        end)
      end
    end

    calculate :anonymous?, :boolean do
      calculation expr(is_nil(email))
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end
