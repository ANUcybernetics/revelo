defmodule Revelo.Diagrams.RelationshipVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Relationship

  calculations do
    calculate :src_name, :string, expr(relationship.src.name)
    calculate :dst_name, :string, expr(relationship.dst.name)
  end

  sqlite do
    table "relationship_votes"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    read :list do
      prepare fn query, context ->
        query
        |> Ash.Query.load([:relationship, :src_name, :dst_name])
        |> Ash.Query.sort([:src_name, :dst_name])
      end
    end

    create :create do
      accept [:type]

      argument :relationship, :struct do
        constraints instance_of: Relationship
        allow_nil? false
      end

      change relate_actor(:voter)
      change manage_relationship(:relationship, type: :append)
    end
  end

  attributes do
    attribute :type, :atom do
      allow_nil? false
      constraints one_of: [:balancing, :reinforcing, :no_relationship]
    end

    timestamps()
  end

  relationships do
    belongs_to :relationship, Revelo.Diagrams.Relationship do
      allow_nil? false
      primary_key? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
    end
  end

  identities do
    identity :unique_vote, [:relationship_id, :voter_id]
  end
end
