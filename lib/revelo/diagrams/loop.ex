defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Relationship

  sqlite do
    table "loops"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:description, :display_order]

      argument :relationships, {:array, :struct} do
        constraints items: [instance_of: Relationship]
        allow_nil? false
      end

      change manage_relationship(:relationships, :influence_relationships, type: :append)
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :description, :string
    attribute :display_order, :integer
    timestamps()
  end

  relationships do
    many_to_many :influence_relationships, Relationship do
      through Revelo.Diagrams.LoopRelationships
      source_attribute_on_join_resource :loop_id
      destination_attribute_on_join_resource :relationship_id
    end
  end
end
