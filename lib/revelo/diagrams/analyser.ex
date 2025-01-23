defmodule Revelo.Diagrams.Analyser do
  @moduledoc false
  @doc """
  Detects cycles in a directed graph.

  Takes a list of edges, where each edge is represented as a tuple {source_id, destination_id} of UUIDs.
  Returns a list of all cycles found in the graph, where each cycle is a list of vertices that form a loop.
  If no cycles exist (the graph is acyclic), returns an empty list.

  Example:
    edges = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid1}]
    find_loops(edges)  # Returns [[uuid1, uuid2, uuid3]]
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

  @doc """
  Compares two loops (represented as lists of UUIDs) to see if they are equal, regardless of starting point.

  Example:
    uuid1 = "550e8400-e29b-41d4-a716-446655440000"
    uuid2 = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    uuid3 = "7c9e6679-7425-40de-944b-e07fc1f90ae7"

    loops_equal?([uuid1, uuid2, uuid3], [uuid2, uuid3, uuid1]) # Returns true
    loops_equal?([uuid1, uuid2, uuid3], [uuid3, uuid1, uuid2]) # Returns true
    loops_equal?([uuid1, uuid2, uuid3], [uuid2, uuid1, uuid3]) # Returns false
  """
  def loops_equal?(loop1, loop2) when length(loop1) == length(loop2) do
    len = length(loop1)

    0..(len - 1)
    |> Enum.map(fn offset ->
      loop2
      |> Stream.cycle()
      |> Stream.drop(offset)
      |> Enum.take(len)
    end)
    |> Enum.any?(&(&1 == loop1))
  end

  def loops_equal?(_, _), do: false
end
