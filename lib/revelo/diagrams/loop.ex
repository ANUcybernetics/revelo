defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Analyser
  alias Revelo.Diagrams.LoopRelationships
  alias Revelo.Diagrams.Relationship

  calculations do
    calculate :type,
              :atom,
              fn loops, _context ->
                Enum.map(loops, fn loop ->
                  if Enum.any?(loop.influence_relationships, &(&1.type == :conflicting)) do
                    :conflicting
                  else
                    balancing_count =
                      Enum.count(loop.influence_relationships, &(&1.type == :balancing))

                    if rem(balancing_count, 2) == 0, do: :reinforcing, else: :balancing
                  end
                end)
              end,
              load: [influence_relationships: [:type]]

    calculate :session_id,
              :uuid,
              fn loops, _context ->
                Enum.map(loops, fn loop ->
                  loop.influence_relationships
                  |> List.first()
                  |> Map.get(:src)
                  |> Map.get(:session_id)
                end)
              end,
              load: [influence_relationships: [src: [:session]]]
  end

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

      validate fn changeset, _context ->
        if Enum.all?(changeset.arguments.relationships, fn rel ->
             rel.type in [:balancing, :reinforcing, :conflicting]
           end) do
          :ok
        else
          {:error, "All relationships must be type :balancing, :reinforcing or :conflicting"}
        end
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

      # check if loop already exists for this session
      # NOTE: if this ever gets too computationally expensive, we could put a hash of the relationships
      # in the DB and then add a unique constraint on that (but not necessary for now)
      validate fn changeset, _context ->
        relationships = changeset.arguments.relationships
        relationship_id_set = MapSet.new(relationships, & &1.id)

        session_id =
          relationships
          |> List.first()
          |> Ash.load!(:src)
          |> Map.get(:src)
          |> Map.get(:session_id)

        duplicate_exists? =
          __MODULE__
          |> Ash.read!(load: :influence_relationships)
          |> Enum.map(fn loop ->
            Map.get(loop, :influence_relationships)
          end)
          |> Enum.filter(fn relationships ->
            first = relationships |> List.first() |> Ash.load!(:src)
            first && first.src.session_id == session_id
          end)
          |> Enum.map(fn relationships ->
            MapSet.new(relationships, & &1.id)
          end)
          |> Enum.any?(fn existing_ids ->
            MapSet.equal?(relationship_id_set, existing_ids)
          end)

        if duplicate_exists? do
          {:error, "A loop with these exact relationships already exists"}
        else
          :ok
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

    action :rescan, {:array, :struct} do
      argument :session_id, :uuid do
        allow_nil? false
      end

      run fn changeset, _context ->
        session_id = changeset.arguments.session_id

        # load relationships
        relationships = Revelo.Diagrams.list_potential_relationships!(session_id)

        # find cycles and create loops from any found
        loops =
          relationships
          |> Analyser.find_loops()
          |> Enum.map(fn cycle_relationships ->
            # Create the loop
            __MODULE__
            |> Ash.Changeset.for_create(:create, %{
              relationships: cycle_relationships
            })
            |> Ash.create!()
          end)

        {:ok, loops}
      end
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
