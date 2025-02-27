defmodule Revelo.RustGraphAnalyserTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Revelo.Diagrams.GraphAnalyser

  describe "cycle scanning in rust via a NIF" do
    test "find_cycles returns empty list for empty graph" do
      # Empty graph should have no cycles
      assert [] = GraphAnalyser.find_cycles([])
    end

    test "find_cycles detects simple cycles" do
      # Create a simple cycle A -> B -> C -> A
      relationships = [
        {"rel1", "node_a", "node_b"},
        {"rel2", "node_b", "node_c"},
        {"rel3", "node_c", "node_a"}
      ]

      cycles = GraphAnalyser.find_cycles(relationships)
      assert length(cycles) == 1

      # The cycle should contain all three relationships
      [cycle] = cycles
      assert MapSet.new(cycle) == MapSet.new(["rel1", "rel2", "rel3"])
    end

    test "find_cycles detects multiple separate cycles" do
      # Create two separate cycles: A -> B -> A and C -> D -> C
      relationships = [
        {"rel1", "node_a", "node_b"},
        {"rel2", "node_b", "node_a"},
        {"rel3", "node_c", "node_d"},
        {"rel4", "node_d", "node_c"}
      ]

      cycles = GraphAnalyser.find_cycles(relationships)
      assert length(cycles) == 2

      # Check both cycles are found
      cycle_ids = Enum.map(cycles, &MapSet.new/1)
      assert MapSet.new(["rel1", "rel2"]) in cycle_ids
      assert MapSet.new(["rel3", "rel4"]) in cycle_ids
    end

    test "find_cycles detects intersecting cycles" do
      # Create a graph with intersecting cycles
      # A -> B -> C -> A and B -> C -> D -> B
      relationships = [
        {"rel1", "node_a", "node_b"},
        {"rel2", "node_b", "node_c"},
        {"rel3", "node_c", "node_a"},
        {"rel4", "node_c", "node_d"},
        {"rel5", "node_d", "node_b"}
      ]

      cycles = GraphAnalyser.find_cycles(relationships)
      assert length(cycles) == 2

      # Check both cycles are found
      cycle_ids = Enum.map(cycles, &MapSet.new/1)
      assert MapSet.new(["rel1", "rel2", "rel3"]) in cycle_ids
      assert MapSet.new(["rel2", "rel4", "rel5"]) in cycle_ids
    end

    test "find_loops works with Relationship structs" do
      user = user()
      session = session(user)

      # Create three variables for a simple cycle
      var1 = variable(session: session, user: user)
      var2 = variable(session: session, user: user)
      var3 = variable(session: session, user: user)

      # Create a simple cycle: var1 -> var2 -> var3 -> var1
      relationships = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      # Find cycles using the find_loops function
      cycles = GraphAnalyser.find_loops(relationships)
      assert length(cycles) == 1

      # The cycle should contain all three relationships
      [cycle] = cycles
      assert MapSet.new(cycle) == MapSet.new(Enum.map(relationships, & &1.id))
    end

    test "cycles_to_relationships converts IDs back to structs" do
      user = user()
      session = session(user)

      # Create variables for a simple cycle
      var1 = variable(session: session, user: user)
      var2 = variable(session: session, user: user)

      # Create a simple cycle: var1 -> var2 -> var1
      relationships = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var1, session: session, user: user)
      ]

      # Find cycles using the find_loops function
      cycles = GraphAnalyser.find_loops(relationships)

      # Convert back to relationship structs
      struct_cycles = GraphAnalyser.cycles_to_relationships(cycles, relationships)

      # Check conversion worked
      assert length(struct_cycles) == 1
      [struct_cycle] = struct_cycles

      # Check that the cycle contains both relationships
      assert length(struct_cycle) == 2
      rel_ids = Enum.map(struct_cycle, & &1.id)
      assert Enum.all?(relationships, fn rel -> rel.id in rel_ids end)
    end

    @tag skip: "takes too long"
    @tag timeout: 120_000
    test "find_cycles stress test with large graph" do
      # Create random large graph
      num_nodes = 15
      connectivity_percentage = 20

      # Create node IDs
      _node_ids = Enum.map(1..num_nodes, fn i -> "node_#{i}" end)

      # Create random relationships with 20% connectivity
      for_result =
        for i <- 1..num_nodes, j <- 1..num_nodes, i != j do
          if :rand.uniform(100) <= connectivity_percentage do
            {"rel_#{i}_#{j}", "node_#{i}", "node_#{j}"}
          end
        end

      relationships = Enum.reject(for_result, &is_nil/1)

      # Make sure we have at least one cycle by adding a closing edge
      # Find nodes that have relationships
      sources = MapSet.new(relationships, fn {_, src, _} -> src end)
      destinations = MapSet.new(relationships, fn {_, _, dst} -> dst end)

      # Add a closing relationship to ensure at least one cycle exists
      source = Enum.random(Enum.to_list(sources))

      destination =
        Enum.find(Enum.to_list(destinations), fn node ->
          # Find a node that doesn't already have an edge from source
          node != source &&
            !Enum.any?(relationships, fn {_, src, dst} -> src == source && dst == node end)
        end)

      relationships = relationships ++ [{"closing_rel", source, destination}]

      # Measure time to find cycles
      {time_microseconds, cycles} =
        :timer.tc(fn ->
          GraphAnalyser.find_cycles(relationships)
        end)

      # Convert to milliseconds for more readable output
      time_ms = time_microseconds / 1000.0

      # Log results
      IO.puts(
        "Cycle detection for graph with #{length(relationships)} relationships took #{time_ms}ms and found #{length(cycles)} cycles"
      )

      # Verify we found at least one cycle
      assert length(cycles) > 0
    end

    @tag skip: "takes too long"
    @tag timeout: 60_000
    test "find_cycles stress test with small dense graph" do
      # Create small but densely connected graph
      num_nodes = 12
      connectivity_percentage = 80

      # Create node IDs
      _node_ids = Enum.map(1..num_nodes, fn i -> "node_#{i}" end)

      # Create random relationships with 80% connectivity
      for_result =
        for i <- 1..num_nodes, j <- 1..num_nodes, i != j do
          if :rand.uniform(100) <= connectivity_percentage do
            {"rel_#{i}_#{j}", "node_#{i}", "node_#{j}"}
          end
        end

      relationships = Enum.reject(for_result, &is_nil/1)

      # With 80% connectivity, cycles will almost certainly exist
      # No need to add a guaranteed closing relationship

      # Measure time to find cycles
      {time_microseconds, cycles} =
        :timer.tc(fn ->
          GraphAnalyser.find_cycles(relationships)
        end)

      # Convert to milliseconds for more readable output
      time_ms = time_microseconds / 1000.0

      # Log results
      IO.puts(
        "Dense graph cycle detection: #{length(relationships)} relationships took #{time_ms}ms and found #{length(cycles)} cycles"
      )

      # there's a _very_ small chance this will fail (because the rels are pseudo-random) but it's a vanisingly small chance if n and connectivity % are high
      assert length(cycles) > 0
    end
  end
end
