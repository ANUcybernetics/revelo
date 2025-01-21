defmodule Revelo.Diagrams.LoopRelationships do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Loop
  alias Revelo.Diagrams.Relationship

  sqlite do
    table "loop_relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      argument :loop, :struct do
        constraints instance_of: Loop
        allow_nil? false
      end

      argument :relationship, :struct do
        constraints instance_of: Relationship
        allow_nil? false
      end

      change manage_relationship(:loop, type: :append)
      change manage_relationship(:relationship, type: :append)
    end
  end

  relationships do
    belongs_to :loop, Loop, primary_key?: true, allow_nil?: false
    belongs_to :relationship, Relationship, primary_key?: true, allow_nil?: false
  end
end
