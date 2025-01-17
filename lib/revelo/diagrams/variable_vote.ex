defmodule Revelo.Diagrams.VariableVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "variable_votes"
    repo Revelo.Repo
  end

  attributes do
    uuid_primary_key :variable_id
    uuid_primary_key :voter_id
    timestamps()
  end

  relationships do
    belongs_to :variable, Revelo.Diagrams.Variable do
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end
  end

  identities do
    identity :unique_vote, [:variable_id, :voter_id]
  end
end
