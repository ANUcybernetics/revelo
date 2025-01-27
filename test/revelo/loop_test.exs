defmodule Revelo.LoopTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  # alias Revelo.Diagrams.Loop
  # alias Revelo.Diagrams.Relationship
  # alias Revelo.Diagrams.Variable

  alias Ash.Error.Changes.InvalidChanges
  alias Revelo.Diagrams.Analyser
  alias Revelo.Diagrams.Loop

  describe "loop actions" do
    test "can create loop" do
      user = user()
      session = session()
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        # add the first variable to the end to "close" the loop
        |> List.insert_at(-1, List.first(variables))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship(src: src, dst: dst, session: session, user: user)
        end)

      input =
        %{
          relationships: relationships,
          story: Faker.Lorem.paragraph()
        }

      loop =
        Loop
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create!()
        |> Ash.load!(:influence_relationships)

      assert MapSet.new(relationships, & &1.id) ==
               MapSet.new(loop.influence_relationships, & &1.id)
    end

    test "can create multiple loops sharing relationships" do
      user = user()
      session = session()

      # Create variables for both loops
      variables = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = variables

      # Create shared relationship between var2 and var3
      shared_relationship = relationship(src: var2, dst: var3, session: session, user: user)

      # First loop: var1 -> var2 -> var3 -> var1
      loop1_rels = [
        relationship(src: var1, dst: var2, session: session, user: user),
        shared_relationship,
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      # Second loop: var2 -> var3 -> var4 -> var2
      loop2_rels = [
        shared_relationship,
        relationship(src: var3, dst: var4, session: session, user: user),
        relationship(src: var4, dst: var2, session: session, user: user)
      ]

      loop1 =
        Loop
        |> Ash.Changeset.for_create(:create, %{relationships: loop1_rels}, actor: user)
        |> Ash.create!()
        |> Ash.load!(:influence_relationships)

      loop2 =
        Loop
        |> Ash.Changeset.for_create(:create, %{relationships: loop2_rels}, actor: user)
        |> Ash.create!()
        |> Ash.load!(:influence_relationships)

      # Verify both loops were created and contain the shared relationship
      assert MapSet.new(loop1_rels, & &1.id) == MapSet.new(loop1.influence_relationships, & &1.id)
      assert MapSet.new(loop2_rels, & &1.id) == MapSet.new(loop2.influence_relationships, & &1.id)
      assert shared_relationship.id in Enum.map(loop1.influence_relationships, & &1.id)
      assert shared_relationship.id in Enum.map(loop2.influence_relationships, & &1.id)
    end

    test "can create non-empty loop using generator" do
      loop = Ash.load!(loop(), :influence_relationships)

      assert loop
      assert length(loop.influence_relationships) > 0
    end
  end

  describe "cycle detection" do
    test "find_loops should find simple cycles" do
      user = user()
      session = session()
      vars = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = vars

      # Simple cycle: var1 -> var2 -> var3 -> var1
      rels = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      loops = Analyser.find_loops(rels)
      assert length(loops) == 1
      assert MapSet.new(rels, & &1.id) == MapSet.new(hd(loops), & &1.id)
    end

    test "find_loops should find intersecting cycles" do
      user = user()
      session = session()
      vars = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = vars

      rels = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user),
        relationship(src: var3, dst: var4, session: session, user: user),
        relationship(src: var4, dst: var2, session: session, user: user)
      ]

      loops = Analyser.find_loops(rels)
      assert length(loops) == 2
    end

    test "find_loops should handle edge cases" do
      user = user()
      session = session()
      vars = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = vars

      # No cycles
      rels1 = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var4, session: session, user: user)
      ]

      assert [] == Analyser.find_loops(rels1)

      # Self loop
      rels2 = [relationship(src: var1, dst: var1, session: session, user: user)]
      loops = Analyser.find_loops(rels2)
      assert length(loops) == 1
      assert MapSet.new(rels2, & &1.id) == MapSet.new(hd(loops), & &1.id)
    end

    test "can create simple a->b->a loop" do
      user = user()
      session = session()

      # Create the two variables for the loop
      [var_a, var_b] = Enum.map(1..2, fn _ -> variable(session: session, user: user) end)

      # Create relationships a->b and b->a
      relationships = [
        relationship(src: var_a, dst: var_b, session: session, user: user),
        relationship(src: var_b, dst: var_a, session: session, user: user)
      ]

      loop =
        Loop
        |> Ash.Changeset.for_create(:create, %{relationships: relationships}, actor: user)
        |> Ash.create!()
        |> Ash.load!(:influence_relationships)

      # Verify loop was created with both relationships
      assert MapSet.new(relationships, & &1.id) ==
               MapSet.new(loop.influence_relationships, & &1.id)
    end

    test "non-loop relationships return error changeset" do
      user = user()
      session = session()

      # Create three variables but don't close the loop
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship(src: src, dst: dst, session: session, user: user)
        end)

      input = %{
        relationships: relationships,
        story: Faker.Lorem.paragraph()
      }

      result =
        Loop
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create()

      assert {:error, changeset} = result

      # this is fragile - update it if the error message changes
      assert [
               %InvalidChanges{
                 message: "Loop does not close back to starting point"
               }
             ] = Map.get(changeset, :errors)
    end

    test "invalid relationships with no loop return error changeset" do
      user = user()
      session = session()

      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create non-sequential relationships that don't form a loop
      relationships = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      input = %{
        relationships: relationships,
        story: Faker.Lorem.paragraph()
      }

      result =
        Loop
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create()

      assert {:error, changeset} = result

      assert [
               %InvalidChanges{
                 message: "Relationships do not form a continuous loop"
               }
             ] = Map.get(changeset, :errors)
    end

    test "scan_session creates loops from relationships" do
      user = user()
      session = session()

      # Create variables for two different loops
      variables = Enum.map(1..5, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4, var5] = variables

      # First loop: var1 -> var2 -> var3 -> var1
      loop1_rels = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      # Second loop: var3 -> var4 -> var5 -> var3
      loop2_rels = [
        relationship(src: var3, dst: var4, session: session, user: user),
        relationship(src: var4, dst: var5, session: session, user: user),
        relationship(src: var5, dst: var3, session: session, user: user)
      ]

      # Run the scan_session action
      loops = Revelo.Diagrams.scan_session!(session.id)

      # Verify both loops were detected
      assert length(loops) == 2

      # Verify loops by comparing their relationships
      loops_with_rels =
        Enum.map(loops, fn loop ->
          Ash.load!(loop, :influence_relationships).influence_relationships
        end)

      # Check that both expected loops were found
      assert Enum.any?(loops_with_rels, fn loop_rels ->
               Enum.all?(
                 loop1_rels,
                 fn rel1 -> Enum.any?(loop_rels, fn rel2 -> rel1.id == rel2.id end) end
               )
             end)

      assert Enum.any?(loops_with_rels, fn loop_rels ->
               Enum.all?(
                 loop2_rels,
                 fn rel1 -> Enum.any?(loop_rels, fn rel2 -> rel1.id == rel2.id end) end
               )
             end)
    end

    test "scan_session returns empty list when no loops exist" do
      user = user()
      session = session()

      # Create variables for a linear path (no loops)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create linear relationships: var1 -> var2 -> var3
      [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user)
      ]

      # Run scan_session and verify empty result
      loops = Revelo.Diagrams.scan_session!(session.id)
      assert loops == []
    end

    test "loops_equal? correctly compares loops" do
      user = user()
      session = session()

      # Create test variables
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create a simple loop: var1 -> var2 -> var3 -> var1
      loop_rels = [
        relationship(src: var1, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var1, session: session, user: user)
      ]

      # Create the same loop but starting from a different point
      rotated_loop = Enum.drop(loop_rels, 1) ++ [List.first(loop_rels)]

      # Different loop with same variables
      different_loop = [
        relationship(src: var1, dst: var3, session: session, user: user),
        relationship(src: var3, dst: var2, session: session, user: user),
        relationship(src: var2, dst: var1, session: session, user: user)
      ]

      # Test equal loops with different starting points
      assert Analyser.loops_equal?(loop_rels, rotated_loop)
      assert Analyser.loops_equal?(rotated_loop, loop_rels)

      # Test different loops
      refute Analyser.loops_equal?(loop_rels, different_loop)

      # Test loops of different lengths
      refute Analyser.loops_equal?(loop_rels, Enum.drop(loop_rels, 1))
    end
  end
end
