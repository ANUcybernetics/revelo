defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "loops"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :description, :string
    timestamps()
  end

  relationships do
    many_to_many :influence_relationships, Revelo.Diagrams.Relationship do
      through Revelo.Diagrams.LoopRelationships
      source_attribute_on_join_resource :loop_id
      destination_attribute_on_join_resource :relationship_id
    end
  end
end
