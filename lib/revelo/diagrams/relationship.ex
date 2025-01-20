defmodule Revelo.Diagrams.Relationship do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Variable
  alias Revelo.Sessions.Session

  sqlite do
    table "relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    # TODO make this use the argument + change manage_relationship pattern, rather
    # than just accepting the :session_id (from memory the issue was that the accept :session_id
    # approach was to get the generate_changeset approach to work, but we should revisit that)
    create :create do
      accept [:description, :hidden?]

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      argument :src, :struct do
        constraints instance_of: Variable
        allow_nil? false
      end

      argument :dst, :struct do
        constraints instance_of: Variable
        allow_nil? false
      end

      primary? true

      change manage_relationship(:session, type: :append)
      change manage_relationship(:src, type: :append)
      change manage_relationship(:dst, type: :append)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :description, :string
    attribute :hidden?, :boolean, allow_nil?: false, default: false

    timestamps()
  end

  relationships do
    belongs_to :session, Session do
      allow_nil? false
    end

    belongs_to :src, Variable do
      allow_nil? false
    end

    belongs_to :dst, Variable do
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.RelationshipVote
  end
end
