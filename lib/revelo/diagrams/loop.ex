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

  @doc """
  Detects cycles in a directed graph.

  Takes a list of edges, where each edge is represented as a tuple {source_id, destination_id} of integers.
  Returns a list of all cycles found in the graph, where each cycle is a list of vertices that form a loop.
  If no cycles exist (the graph is acyclic), returns an empty list.

  Example:
    edges = [{1, 2}, {2, 3}, {3, 1}]
    find_loops(edges)  # Returns [[1, 2, 3]]
  """
  def find_loops(edges) do
    graph =
      Enum.reduce(edges, %{}, fn {src, dst}, acc ->
        Map.update(acc, src, [dst], fn existing -> [dst | existing] end)
      end)

    vertices = edges |> Enum.flat_map(fn {src, dst} -> [src, dst] end) |> Enum.uniq()

    vertices
    |> Enum.reduce([], fn start, cycles ->
      visited = MapSet.new()
      path = []

      find_loops_helper(start, start, graph, visited, path, cycles)
    end)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.uniq()
    |> Enum.map(&normalize_cycle/1)
    |> Enum.uniq()
  end

  defp find_loops_helper(current, start, graph, visited, path, cycles) do
    if current in visited do
      if current == start and length(path) > 0 do
        [path | cycles]
      else
        cycles
      end
    else
      visited = MapSet.put(visited, current)
      path = [current | path]

      case Map.get(graph, current, []) do
        [] ->
          cycles

        neighbors ->
          Enum.reduce(neighbors, cycles, fn neighbor, acc ->
            find_loops_helper(neighbor, start, graph, visited, path, acc)
          end)
      end
    end
  end

  defp normalize_cycle(cycle) do
    min_element = Enum.min(cycle)
    {prefix, suffix} = Enum.split_while(cycle, fn x -> x != min_element end)
    suffix ++ prefix
  end
end
