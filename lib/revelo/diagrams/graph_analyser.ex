defmodule Revelo.Diagrams.GraphAnalyser do
  @moduledoc false
  use Rustler, otp_app: :revelo, crate: "graph_analyser"

  alias Revelo.Diagrams.Relationship

  @doc """
  Finds all cycles in a graph represented by relationships.

  Takes a list of {relationship_uuid, src_uuid, dst_uuid} tuples and returns
  a list of cycles, where each cycle is a list of relationship UUIDs.

  Each cycle is sorted such that the relationship with the lexicographically
  smallest UUID appears first.
  """
  @spec find_cycles([{String.t(), String.t(), String.t()}]) :: [[String.t()]]
  def find_cycles(_relationships), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Finds all loops in a graph using the Relationship struct.

  Takes a list of Relationship structs and returns a list of cycles,
  where each cycle is a list of Relationship structs.
  """
  @spec find_loops([Relationship.t()]) :: [[Relationship.t()]]
  def find_loops(relationships) do
    # Create a map for quick relationship lookup
    rel_map = Map.new(relationships, fn rel -> {rel.id, rel} end)

    # Convert Relationship structs to tuples
    relationship_tuples =
      Enum.map(relationships, fn rel ->
        {rel.id, rel.src_id, rel.dst_id}
      end)

    # Call the NIF function and convert IDs back to Relationship structs
    relationship_tuples
    |> find_cycles()
    |> Enum.map(fn cycle ->
      Enum.map(cycle, fn rel_id ->
        Map.get(rel_map, rel_id)
      end)
    end)
  end

  @doc """
  Helper function to convert relationship IDs back to Relationship structs.

  Takes the output of find_cycles/1 and the original list of relationships,
  and returns the cycles with full Relationship structs.
  """
  @spec cycles_to_relationships([[String.t()]], [Relationship.t()]) ::
          [[Relationship.t()]]
  def cycles_to_relationships(cycles, relationships) do
    # Create a map of relationship IDs to Relationship structs
    rel_map = Map.new(relationships, fn rel -> {rel.id, rel} end)

    # Convert each cycle
    Enum.map(cycles, fn cycle ->
      Enum.map(cycle, fn rel_id ->
        Map.get(rel_map, rel_id)
      end)
    end)
  end

  @doc """
  Compares two loops to determine if they contain the same relationships,
  regardless of starting point.

  This function checks if two loops have the same relationships, even if they
  start at different points in the cycle.
  """
  @spec loops_equal?([Relationship.t()], [Relationship.t()]) :: boolean()
  def loops_equal?(loop1, loop2) do
    # If the loops have different lengths, they can't be equal
    if length(loop1) == length(loop2) do
      # Convert to sets of IDs for comparison
      loop1_ids = MapSet.new(loop1, & &1.id)
      loop2_ids = MapSet.new(loop2, & &1.id)

      # If they have the same relationships, the sets will be equal
      MapSet.equal?(loop1_ids, loop2_ids)
    else
      false
    end
  end
end
