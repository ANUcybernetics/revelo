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

    create :create do
      accept [:description, :is_key?, :included?]
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
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :is_key?, :boolean, allow_nil?: false, default: false
    attribute :included?, :boolean, allow_nil?: false, default: false

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
