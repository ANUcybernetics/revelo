defmodule Revelo.Diagrams.LoopRelationships do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Loop

  sqlite do
    table "loop_relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :loop, Loop, primary_key?: true, allow_nil?: false
    belongs_to :relationship, Loop, primary_key?: true, allow_nil?: false
  end
end
