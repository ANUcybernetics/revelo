defmodule Revelo.Diagrams.Analyser do
  @moduledoc false
  @doc """
  Detects cycles in a directed graph.

  Takes a list of Relationship structs.
  Returns a list of all cycles found in the graph, where each cycle is a list of relationships that form a loop.
  If no cycles exist (the graph is acyclic), returns an empty list.

  Example:
    relationships = [%Relationship{src_id: uuid1, dst_id: uuid2}, ...]
    find_loops(relationships)  # Returns [[%Relationship{...}, %Relationship{...}, %Relationship{...}]]
  """
  def find_loops(relationships) do
    edges = relationships_to_edges(relationships)

    # Build graph representation
    graph =
      Enum.reduce(edges, %{}, fn {src, dst}, acc ->
        Map.update(acc, src, [dst], fn existing -> [dst | existing] end)
      end)

    vertices = edges |> Enum.flat_map(fn {src, dst} -> [src, dst] end) |> Enum.uniq()

    # Create lookup map for relationships by src/dst pair
    relationship_lookup =
      Enum.reduce(relationships, %{}, fn rel, acc ->
        Map.put(acc, {rel.src_id, rel.dst_id}, rel)
      end)

    vertices
    |> Enum.reduce([], fn start, cycles ->
      visited = MapSet.new()
      path = []

      find_loops_helper(start, start, graph, visited, path, cycles)
    end)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.map(&normalize_cycle/1)
    |> Enum.uniq()
    |> Enum.map(fn cycle ->
      # Convert vertex cycles back to relationship cycles
      cycle
      |> Enum.zip(Enum.drop(cycle, 1) ++ [List.first(cycle)])
      |> Enum.map(fn {src, dst} -> Map.get(relationship_lookup, {src, dst}) end)
    end)
  end

  defp relationships_to_edges(relationships) do
    Enum.map(relationships, fn rel -> {rel.src_id, rel.dst_id} end)
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

  # This function normalizes a cycle by rotating it such that the smallest element
  # (according to the standard ordering of the elements) comes first. This ensures
  # that cycles which are rotations of each other are considered equal.
  defp normalize_cycle(cycle) do
    min_element = Enum.min(cycle)
    {prefix, suffix} = Enum.split_while(cycle, fn x -> x != min_element end)
    suffix ++ prefix
  end

  @doc """
  Compares two loops (represented as lists of Relationship structs) to see if they are equal, regardless of starting point.

  Example:
    rel1 = %Relationship{src_id: uuid1, dst_id: uuid2}
    rel2 = %Relationship{src_id: uuid2, dst_id: uuid3}
    rel3 = %Relationship{src_id: uuid3, dst_id: uuid1}

    loops_equal?([rel1, rel2, rel3], [rel2, rel3, rel1]) # Returns true
    loops_equal?([rel1, rel2, rel3], [rel3, rel1, rel2]) # Returns true
    loops_equal?([rel1, rel2, rel3], [rel2, rel1, rel3]) # Returns false
  """
  def loops_equal?(loop1, loop2) when length(loop1) == length(loop2) do
    MapSet.new(Enum.map(loop1, & &1.id)) == MapSet.new(Enum.map(loop2, & &1.id))
  end

  def loops_equal?(_, _), do: false
end
