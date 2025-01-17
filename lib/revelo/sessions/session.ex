defmodule Revelo.Sessions.Session do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Sessions,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "sessions"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      accept [:description, :report]
      primary? true

      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))
    end

    update :add_participants do
      argument :participants, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:participants, type: :append)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :description, :string
    attribute :report, :string
    timestamps()
  end

  relationships do
    has_many :context_docs, Revelo.Sessions.ContextDoc
    has_many :variables, Revelo.Diagrams.Variable
    has_many :influence_relationships, Revelo.Diagrams.Relationship

    many_to_many :participants, Revelo.Accounts.User do
      through Revelo.Sessions.SessionParticipants
      source_attribute_on_join_resource :session_id
      destination_attribute_on_join_resource :participant_id
    end
  end
end
