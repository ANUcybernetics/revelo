defmodule Revelo.Diagrams.LoopVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Loop

  sqlite do
    table "loop_votes"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      argument :loop, :struct do
        constraints instance_of: Loop
        allow_nil? false
      end

      change relate_actor(:voter)
      change manage_relationship(:loop, type: :append)
    end
  end

  attributes do
    timestamps()
  end

  relationships do
    belongs_to :loop, Revelo.Diagrams.Loop do
      allow_nil? false
      primary_key? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
    end
  end

  identities do
    identity :unique_vote, [:loop_id, :voter_id]
  end
end
