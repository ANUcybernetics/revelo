defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.LoopRelationships
  alias Revelo.Diagrams.Relationship

  sqlite do
    table "loops"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:story, :display_order]

      argument :relationships, {:array, :struct} do
        constraints items: [instance_of: Relationship]
        allow_nil? false
      end

      # check that the relationships form a loop
      validate fn changeset, context ->
        relationships = changeset.arguments.relationships
        first_relationship = List.first(relationships)

        result =
          Enum.reduce_while(relationships, {:ok, first_relationship.src_id}, fn rel, {:ok, current_src} ->
            if rel.src_id == current_src do
              {:cont, {:ok, rel.dst_id}}
            else
              {:halt, {:error, "Relationships do not form a continuous loop"}}
            end
          end)

        case result do
          {:ok, final_dst} ->
            if final_dst == first_relationship.src_id do
              :ok
            else
              {:error, "Loop does not close back to starting point"}
            end

          {:error, msg} ->
            {:error, msg}
        end
      end

      # this is necessary as an :after_action because in the loop's create action there's no loop ID yet,
      # so it can't be set in the join table
      change after_action(fn changeset, record, _context ->
               Enum.each(changeset.arguments.relationships, fn relationship ->
                 LoopRelationships
                 |> Ash.Changeset.for_create(:create, %{loop: record, relationship: relationship})
                 |> Ash.create!()
               end)

               {:ok, record}
             end)
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :story, :string
    attribute :display_order, :integer
    timestamps()
  end

  relationships do
    many_to_many :influence_relationships, Relationship do
      through LoopRelationships
      source_attribute_on_join_resource :loop_id
      destination_attribute_on_join_resource :relationship_id
    end
  end
end
