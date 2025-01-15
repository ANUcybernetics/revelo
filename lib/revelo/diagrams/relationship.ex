defmodule Revelo.Diagrams.Relationship do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Variable

  sqlite do
    table "relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :description, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :session, Revelo.Sessions.Session do
      attribute_type :uuid_v7
      allow_nil? false
    end

    belongs_to :src, Variable do
      attribute_type :uuid_v7
      allow_nil? false
    end

    belongs_to :dst, Variable do
      attribute_type :uuid_v7
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.RelationshipVote
  end
end
