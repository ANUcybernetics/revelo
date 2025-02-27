defmodule Revelo.Diagrams.Loop do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshPostgres.DataLayer

  alias Revelo.Diagrams
  alias Revelo.Diagrams.GraphAnalyser
  alias Revelo.Diagrams.LoopRelationships
  alias Revelo.Diagrams.Relationship
  alias Revelo.Sessions.Session

  require Ash.Query
  require Ash.Sort

  postgres do
    table "loops"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(influence_relationships_join_assoc.relationship.src.session_id == ^arg(:session_id))

      prepare build(
                load: [
                  :type,
                  :influence_relationships_join_assoc,
                  influence_relationships: [:type, :dst, src: :session]
                ]
              )
    end

    create :create do
      accept [:story, :display_order, :title, :relationship_hash]

      argument :relationships, {:array, :struct} do
        constraints items: [instance_of: Relationship]
        allow_nil? false
      end

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      # Connect the provided session to the loop
      change manage_relationship(:session, type: :append_and_remove)

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

      # Generate relationship hash and check duplicates
      change fn changeset, _context ->
        relationships = Ash.load!(changeset.arguments.relationships, :type)
        relationship_hash = generate_relationship_hash(relationships)

        # Check for duplicate by hash
        duplicate_exists? =
          __MODULE__
          |> Ash.Query.filter(relationship_hash == ^relationship_hash)
          |> Ash.exists?()

        if duplicate_exists? do
          Ash.Changeset.add_error(
            changeset,
            :relationships,
            "A loop with these exact relationships already exists"
          )
        else
          Ash.Changeset.force_change_attribute(changeset, :relationship_hash, relationship_hash)
        end
      end

      # this is necessary as an :after_action because in the loop's create action there's no loop ID yet,
      # so it can't be set in the join table
      change after_action(fn changeset, record, _context ->
               changeset.arguments.relationships
               |> Enum.with_index()
               |> Enum.each(fn {relationship, index} ->
                 LoopRelationships
                 |> Ash.Changeset.for_create(:create, %{
                   loop: record,
                   relationship: relationship,
                   loop_index: index
                 })
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

        # Get the session once at the beginning
        session = Ash.get!(Session, session_id)

        # Get existing loop hashes
        existing_loop_hashes =
          session_id
          |> Revelo.Diagrams.list_loops!()
          |> Map.new(fn loop -> {loop.relationship_hash, loop.id} end)

        # Get all actual relationships for this session
        relationships = Diagrams.list_actual_relationships!(session_id)

        # Find all possible loops and create hashes
        new_loops_with_hashes =
          relationships
          |> GraphAnalyser.find_loops()
          |> Map.new(fn loop_relationships ->
            relationship_hash = generate_relationship_hash(loop_relationships)
            {relationship_hash, loop_relationships}
          end)

        # Find loops to delete (in existing but not in new)
        loops_to_delete_ids =
          existing_loop_hashes
          |> Map.keys()
          |> Enum.filter(fn hash -> !Map.has_key?(new_loops_with_hashes, hash) end)
          |> Enum.map(fn hash -> existing_loop_hashes[hash] end)

        # Find loops to create (in new but not in existing)
        loops_to_create =
          new_loops_with_hashes
          |> Map.keys()
          |> Enum.filter(fn hash -> !Map.has_key?(existing_loop_hashes, hash) end)
          |> Enum.map(fn hash ->
            %{
              session: session,
              relationships: new_loops_with_hashes[hash]
            }
          end)

        # Delete loops that need to be removed
        if !Enum.empty?(loops_to_delete_ids) do
          # First, delete the join records to avoid foreign key constraints
          LoopRelationships
          |> Ash.Query.filter(loop_id in ^loops_to_delete_ids)
          |> Ash.bulk_destroy!(:destroy, %{})

          # Then delete the loops
          __MODULE__
          |> Ash.Query.filter(id in ^loops_to_delete_ids)
          |> Ash.bulk_destroy!(:destroy, %{})
        end

        # Create new loops with proper error handling
        created_loops =
          if Enum.empty?(loops_to_create) do
            []
          else
            bulk_result =
              Ash.bulk_create(
                loops_to_create,
                __MODULE__,
                :create,
                return_records?: true,
                return_errors?: true,
                return_notifications?: true
              )

            case bulk_result do
              %{status: :success, records: records} ->
                records

              %{status: :error, errors: errors} ->
                # Explicitly raise an error with details
                raise "Failed to create new loops: #{inspect(errors)}"
            end
          end

        # Return all loops for this session
        all_loops = Revelo.Diagrams.list_loops!(session_id)

        {:ok, all_loops}
      end
    end

    update :generate_story do
      require_atomic? false

      change fn changeset, _ ->
        loop =
          Ash.load!(changeset.data, [
            :type,
            :session,
            influence_relationships: [:src, :dst, :type]
          ])

        relationship_string =
          loop.influence_relationships
          |> Enum.reduce({"", []}, fn rel, {prev_connector, acc} ->
            connector =
              case {prev_connector, rel.type} do
                {"", :inverse} -> :decrease
                {"", :direct} -> :increase
                {:decrease, :inverse} -> :increase
                {:decrease, :direct} -> :decrease
                {:increase, :inverse} -> :decrease
                {:increase, :direct} -> :increase
              end

            cur_text =
              case {prev_connector, connector} do
                {"", :decrease} ->
                  "Increasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

                {"", :increase} ->
                  "Increasing #{rel.src.name} directly causes #{rel.dst.name} to increase"

                {:decrease, :increase} ->
                  "Decreasing #{rel.src.name} directly causes #{rel.dst.name} to increase"

                {:decrease, :decrease} ->
                  "Decreasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

                {:increase, :decrease} ->
                  "Increasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

                {:increase, :increase} ->
                  "Increasing #{rel.src.name} directly causes #{rel.dst.name} to increase"
              end

            {connector, acc ++ [cur_text]}
          end)
          |> elem(1)
          |> Enum.join("; ")

        session_description = Ash.load!(loop.session, :description).description

        {:ok, %{story: story, title: title}} =
          Revelo.LLM.generate_story(
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
    attribute :relationship_hash, :string
    timestamps()
  end

  relationships do
    many_to_many :influence_relationships, Relationship do
      through LoopRelationships
      source_attribute_on_join_resource :loop_id
      destination_attribute_on_join_resource :relationship_id
      sort [Ash.Sort.expr_sort(source(influence_relationships_join_assoc.loop_index))]
    end

    belongs_to :session, Session do
      allow_nil? false
    end
  end

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
  end

  identities do
    identity :relationship_hash, [:relationship_hash]
  end

  # Generate a unique deterministic hash for a set of relationships
  defp generate_relationship_hash(relationships) do
    relationships
    |> Enum.map(&"#{&1.id}:#{&1.type}")
    |> Enum.sort()
    |> Enum.join(">")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
