defmodule Revelo.Sessions.Session do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Sessions,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Accounts.User
  alias Revelo.Sessions.SessionParticipants

  sqlite do
    table "sessions"
    repo Revelo.Repo
  end

  actions do
    defaults [:destroy, update: :*]

    read :list do
      primary? true
      prepare build(sort: [inserted_at: :desc])
    end

    create :create do
      accept [:description, :report]
      primary? true

      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))
    end

    update :add_participant do
      argument :participant, :struct do
        constraints instance_of: User
        allow_nil? false
      end

      argument :facilitator, :boolean, default: false

      change manage_relationship(:participant, :participants, type: :append)

      change after_transaction(fn changeset, {:ok, session}, _context ->
               participant_id = changeset.arguments.participant.id

               SessionParticipants
               |> Ash.get!(
                 session_id: session.id,
                 participant_id: participant_id
               )
               |> Ash.Changeset.for_update(:set_facilitation_status, %{
                 facilitator: changeset.arguments.facilitator
               })
               |> Ash.update!()

               {:ok, session}
             end)
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

    many_to_many :participants, User do
      through SessionParticipants
      source_attribute_on_join_resource :session_id
      destination_attribute_on_join_resource :participant_id
    end
  end
end
