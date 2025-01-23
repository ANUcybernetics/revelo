defmodule Revelo.Diagrams.Variable do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Accounts.User
  alias Revelo.Sessions.Session

  sqlite do
    table "variables"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    read :list do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(hidden? == false and session.id == ^arg(:session_id))
      prepare build(sort: :name)
    end

    create :create do
      accept [:is_key?, :hidden?]
      primary? true

      argument :name, :string do
        allow_nil? false
      end

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      change relate_actor(:creator)
      change manage_relationship(:session, type: :append)
      change set_attribute(:name, arg(:name))
    end

    update :rename do
      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))
    end

    update :set_key do
      change set_attribute(:is_key?, true)
    end

    update :unset_key do
      change set_attribute(:is_key?, false)
    end

    update :hide do
      change set_attribute(:hidden?, true)
    end

    update :unhide do
      change set_attribute(:hidden?, false)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :is_key?, :boolean, allow_nil?: false, default: false
    attribute :hidden?, :boolean, allow_nil?: false, default: false

    timestamps()
  end

  relationships do
    belongs_to :session, Session do
      allow_nil? false
    end

    belongs_to :creator, User do
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.VariableVote do
      destination_attribute :variable_id
    end
  end

  identities do
    identity :unique_name, [:name, :session_id]
  end
end
