defmodule Revelo.Sessions.Session do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Sessions,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Accounts.User
  alias Revelo.Sessions.SessionParticipants

  require Logger

  sqlite do
    table "sessions"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      prepare build(sort: [inserted_at: :desc])
    end

    # TODO: ensure that anonymous users can't create sessions
    create :create do
      accept [:description, :report]
      primary? true

      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))

      change after_action(fn _changeset, session, context ->
               session =
                 Revelo.Sessions.add_participant!(session, context.actor, true)

               {:ok, session}
             end)
    end

    update :update do
      accept [:name, :description]
      primary? true
    end

    update :add_participant do
      argument :participant, :struct do
        constraints instance_of: User
        allow_nil? false
      end

      argument :facilitator?, :boolean, default: false

      change manage_relationship(:participant, :participants, type: :append)

      change after_transaction(fn
               changeset, {:ok, session}, _context ->
                 participant_id = changeset.arguments.participant.id

                 SessionParticipants
                 |> Ash.get!(
                   session_id: session.id,
                   participant_id: participant_id
                 )
                 |> Ash.Changeset.for_update(:set_facilitation_status, %{
                   facilitator?: changeset.arguments.facilitator?
                 })
                 |> Ash.update!()

                 {:ok, session}

               changeset, {:error, reason}, _context ->
                 Logger.debug(
                   "Failed to execute transaction for action #{changeset.action.name} on #{inspect(changeset.resource)}, reason: #{inspect(reason)}"
                 )

                 {:error, reason}
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
