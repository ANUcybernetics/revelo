defmodule Revelo.Diagrams.VariableVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshPostgres.DataLayer

  alias Revelo.Diagrams.Variable

  postgres do
    table "variable_votes"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(variable.session_id == ^arg(:session_id))

      prepare build(
                load: [:variable, :variable_name],
                sort: [:variable_name]
              )
    end

    create :create do
      argument :variable, :struct do
        constraints instance_of: Variable
        allow_nil? false
      end

      change relate_actor(:voter)
      change manage_relationship(:variable, type: :append)
    end
  end

  attributes do
    timestamps()
  end

  relationships do
    belongs_to :variable, Variable do
      allow_nil? false
      primary_key? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
    end
  end

  calculations do
    calculate :variable_name, :string, expr(variable.name)
  end

  identities do
    identity :unique_vote, [:variable_id, :voter_id]
  end
end
