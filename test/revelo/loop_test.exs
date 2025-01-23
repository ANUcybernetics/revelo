defmodule Revelo.LoopTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  # alias Revelo.Diagrams.Loop
  # alias Revelo.Diagrams.Relationship
  # alias Revelo.Diagrams.Variable

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
      loop1 = Loop.find_loops(edges1)
      assert Loop.loops_equal?([uuid1, uuid2, uuid3], hd(loop1))

      # Two intersecting cycles: uuid1->uuid2->uuid3->uuid1 and uuid2->uuid3->uuid4->uuid2
      edges2 = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid1}, {uuid3, uuid4}, {uuid4, uuid2}]
      loops2 = Loop.find_loops(edges2)

      assert length(loops2) == 2
      assert Enum.any?(loops2, &Loop.loops_equal?(&1, [uuid1, uuid2, uuid3]))
      assert Enum.any?(loops2, &Loop.loops_equal?(&1, [uuid2, uuid3, uuid4]))

      # No cycles
      edges3 = [{uuid1, uuid2}, {uuid2, uuid3}, {uuid3, uuid4}]
      assert [] == Loop.find_loops(edges3)

      # Self loop
      edges4 = [{uuid1, uuid1}]
      assert Loop.loops_equal?([uuid1], hd(Loop.find_loops(edges4)))
    end
  end
end
