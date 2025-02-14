defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams
  alias Revelo.Diagrams.Analyser
  alias Revelo.Diagrams.LoopRelationships
  alias Revelo.Diagrams.Relationship

  require Ash.Query

  calculations do
    calculate :type,
              :atom,
              fn loops, _context ->
                Enum.map(loops, fn loop ->
                  if Enum.any?(loop.influence_relationships, &(&1.type == :conflicting)) do
                    :conflicting
                  else
                    inverse_count =
                      Enum.count(loop.influence_relationships, &(&1.type == :inverse))

                    if rem(inverse_count, 2) == 0, do: :reinforcing, else: :balancing
                  end
                end)
              end,
              load: [influence_relationships: [:type]]

    calculate :session,
              :uuid,
              fn loops, _context ->
                Enum.map(loops, fn loop ->
                  loop.influence_relationships
                  |> List.first()
                  |> Map.get(:src)
                  |> Map.get(:session)
                end)
              end,
              load: [influence_relationships: [src: [:session]]]
  end

  sqlite do
    table "loops"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      argument :session_id, :uuid do
        allow_nil? false
      end

      prepare fn query, _context ->
        query
        |> Ash.Query.load([:type, influence_relationships: [:type, src: :session]])
        |> Ash.Query.filter(influence_relationships: [src: [session: [id: query.arguments.session_id]]])
      end
    end

    create :create do
      accept [:story, :display_order, :title]

      argument :relationships, {:array, :struct} do
        constraints items: [instance_of: Relationship]
        allow_nil? false
      end

      validate fn changeset, _context ->
        relationships = Enum.map(changeset.arguments.relationships, &Ash.load!(&1, :type))

        case Enum.find(relationships, &(&1.type == :no_relationship)) do
          nil ->
            :ok

          rel ->
            {:error,
             "Relationship between #{rel.src.name} and #{rel.dst.name} was voted 'no relationship' and can't be part of a loop"}
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

        # First get existing loops and actual relationships
        existing_loops = Diagrams.list_loops!(session_id)
        relationships = Diagrams.list_actual_relationships!(session_id)
        relationship_ids = MapSet.new(relationships, & &1.id)

        # Filter loops with missing relationships
        loops_to_delete =
          Enum.filter(existing_loops, fn loop ->
            # Check if any of the loop's relationships are no longer in the actual relationships list
            Enum.any?(loop.influence_relationships, fn rel ->
              not MapSet.member?(relationship_ids, rel.id)
            end)
          end)

        # Delete join table rows and loops that need to be removed
        if not Enum.empty?(loops_to_delete) do
          # Delete loop relationship records for affected loops
          LoopRelationships
          |> Ash.Query.filter(loop_id in ^Enum.map(loops_to_delete, & &1.id))
          |> Ash.read!()
          |> Enum.each(&Ash.destroy!/1)

          # Delete the affected loops
          Enum.each(loops_to_delete, &Ash.destroy!/1)
        end

        # First calculate remaining_loops since we'll use it multiple times
        remaining_loops =
          Enum.reject(existing_loops, fn loop ->
            loop_id = loop.id
            Enum.any?(loops_to_delete, fn deleted -> deleted.id == loop_id end)
          end)

        # Find cycles and create new loops
        new_loops =
          relationships
          |> Analyser.find_loops()
          |> Enum.reject(fn new_loop ->
            Enum.any?(remaining_loops, fn existing_loop ->
              Analyser.loops_equal?(new_loop, existing_loop.influence_relationships)
            end)
          end)
          |> Enum.map(&Diagrams.create_loop!/1)

        # Return remaining existing loops plus new loops
        {:ok, remaining_loops ++ new_loops}
      end
    end

    update :generate_story do
      change fn changeset, _ ->
        loop =
          Ash.load!(changeset.data, [
            :type,
            :session,
            influence_relationships: [:src, :dst]
          ])

        relationship_string =
          Enum.map_join(loop.influence_relationships, "; ", fn rel ->
            "#{rel.src.name} #{if rel.type == :inverse, do: "decreases", else: "increases"} #{rel.dst.name}"
          end)

        session_description = Ash.load!(loop.session, :description).description

        {:ok, %{story: story}} =
          Revelo.LLM.generate_story(
            session_description,
            relationship_string,
            Atom.to_string(loop.type)
          )

        {:ok, %{title: title}} =
          Revelo.LLM.generate_title(
            session_description,
            relationship_string,
            Atom.to_string(loop.type)
          )

        changeset
        |> Ash.Changeset.force_change_attribute(:story, story)
        |> Ash.Changeset.force_change_attribute(:title, title)
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string
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
