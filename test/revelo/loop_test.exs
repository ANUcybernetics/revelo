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
    test "find_loops should find cycles in test graphs" do
      # Simple cycle: uuid1 -> uuid2 -> uuid3 -> uuid1
      uuid1 = Ecto.UUID.generate()
      uuid2 = Ecto.UUID.generate()
      uuid3 = Ecto.UUID.generate()
      uuid4 = Ecto.UUID.generate()

      edges1 = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid1}]
      loop1 = Analyser.find_loops(edges1)
      assert Analyser.loops_equal?([uuid1, uuid2, uuid3], hd(loop1))

      # Two intersecting cycles: uuid1->uuid2->uuid3->uuid1 and uuid2->uuid3->uuid4->uuid2
      edges2 = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid1}, {uuid3, uuid4}, {uuid4, uuid2}]
      loops2 = Analyser.find_loops(edges2)

      assert length(loops2) == 2
      assert Enum.any?(loops2, &Analyser.loops_equal?(&1, [uuid1, uuid2, uuid3]))
      assert Enum.any?(loops2, &Analyser.loops_equal?(&1, [uuid2, uuid3, uuid4]))

      # No cycles
      edges3 = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid4}]
      assert [] == Analyser.find_loops(edges3)

      # Self loop
      edges4 = [{uuid1, uuid1}]

      assert Analyser.loops_equal?(
               [uuid1],
               hd(Analyser.find_loops(edges4))
             )
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
          loop
          |> Ash.load!(:influence_relationships)
          |> Map.get(:influence_relationships)
          |> Enum.map(fn rel -> {rel.src_id, rel.dst_id} end)
        end)

      # Source loop relationships as tuples
      loop1_tuples = Enum.map(loop1_rels, fn rel -> {rel.src_id, rel.dst_id} end)
      loop2_tuples = Enum.map(loop2_rels, fn rel -> {rel.src_id, rel.dst_id} end)

      # Check that both expected loops were found
      assert Enum.any?(loops_with_rels, fn loop_rels ->
               Analyser.loops_equal?(
                 Enum.map(loop_rels, fn {src, _dst} -> src end),
                 Enum.map(loop1_tuples, fn {src, _dst} -> src end)
               )
             end)

      assert Enum.any?(loops_with_rels, fn loop_rels ->
               Analyser.loops_equal?(
                 Enum.map(loop_rels, fn {src, _dst} -> src end),
                 Enum.map(loop2_tuples, fn {src, _dst} -> src end)
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
  end
end
