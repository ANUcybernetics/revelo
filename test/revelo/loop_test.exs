defmodule Revelo.LoopTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  # alias Revelo.Diagrams.Loop
  # alias Revelo.Diagrams.Relationship
  # alias Revelo.Diagrams.Variable

  alias Ash.Error.Changes.InvalidChanges
  alias Revelo.Diagrams.Analyser

  describe "loop actions" do
    test "can create loop" do
      user = user()
      session = session(user)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        # add the first variable to the end to "close" the loop
        |> List.insert_at(-1, List.first(variables))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session,
            user: user,
            vote_type: :direct
          )
        end)

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:influence_relationships)

      assert MapSet.new(relationships, & &1.id) ==
               MapSet.new(loop.influence_relationships, & &1.id)
    end

    test "session_id calculation returns correct session ID" do
      user = user()
      session = session(user)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        |> List.insert_at(-1, List.first(variables))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session,
            user: user,
            vote_type: :direct
          )
        end)

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:session)

      assert loop.session.id == session.id
    end

    test "list_loops only returns loops from specified session" do
      user = user()
      session1 = session(user)
      session2 = session(user)

      # Create variables and relationships for session 1
      variables1 = Enum.map(1..3, fn _ -> variable(session: session1, user: user) end)

      relationships1 =
        variables1
        # add the first variable to the end to "close" the loop
        |> List.insert_at(-1, List.first(variables1))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session1,
            user: user,
            vote_type: :direct
          )
        end)

      # Create loop in session 1
      loop1 = Revelo.Diagrams.create_loop!(relationships1, actor: user)

      # Create variables and relationships for session 2
      variables2 = Enum.map(1..3, fn _ -> variable(session: session2, user: user) end)

      relationships2 =
        variables2
        |> List.insert_at(-1, List.first(variables2))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session2,
            user: user,
            vote_type: :direct
          )
        end)

      # Create loop in session 2
      loop2 = Revelo.Diagrams.create_loop!(relationships2, actor: user)

      # Verify list_loops only returns loops from the specified session
      session1_loops = Revelo.Diagrams.list_loops!(session1.id)
      session2_loops = Revelo.Diagrams.list_loops!(session2.id)

      assert length(session1_loops) == 1
      assert length(session2_loops) == 1
      assert List.first(session1_loops).id == loop1.id
      assert List.first(session2_loops).id == loop2.id
    end

    test "can create multiple loops sharing relationships" do
      user = user()
      session = session(user)

      # Create variables for both loops
      variables = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = variables

      # Create shared relationship between var2 and var3
      shared_relationship =
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        )

      # First loop: var1 -> var2 -> var3 -> var1
      loop1_rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        shared_relationship,
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Second loop: var2 -> var3 -> var4 -> var2
      loop2_rels = [
        shared_relationship,
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var4,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loop1 =
        loop1_rels
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:influence_relationships)

      loop2 =
        loop2_rels
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:influence_relationships)

      # Verify both loops were created and contain the shared relationship
      assert MapSet.new(loop1_rels, & &1.id) == MapSet.new(loop1.influence_relationships, & &1.id)
      assert MapSet.new(loop2_rels, & &1.id) == MapSet.new(loop2.influence_relationships, & &1.id)
      assert shared_relationship.id in Enum.map(loop1.influence_relationships, & &1.id)
      assert shared_relationship.id in Enum.map(loop2.influence_relationships, & &1.id)
    end

    test "creating duplicate loop returns error" do
      user = user()
      session = session(user)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        # add the first variable to the end to "close" the loop
        |> List.insert_at(-1, List.first(variables))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session,
            user: user,
            vote_type: :direct
          )
        end)

      # Create first loop successfully
      Revelo.Diagrams.create_loop!(relationships, actor: user)

      # Attempt to create duplicate loop
      result = Revelo.Diagrams.create_loop(relationships, actor: user)

      assert {:error, changeset} = result

      assert [%InvalidChanges{message: "A loop with these exact relationships already exists"}] =
               Map.get(changeset, :errors)
    end

    test "relationships without votes return validation error" do
      user = user()
      session = session(user)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        |> List.insert_at(-1, List.first(variables))
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship(src: src, dst: dst, session: session, user: user)
        end)

      result = Revelo.Diagrams.create_loop(relationships, actor: user)
      assert {:error, changeset} = result

      assert [
               %InvalidChanges{
                 message: msg
               }
             ] = Map.get(changeset, :errors)

      assert String.ends_with?(msg, "was voted 'no relationship' and can't be part of a loop")
    end
  end

  describe "cycle detection" do
    test "find_loops should find simple cycles" do
      user = user()
      session = session(user)
      vars = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = vars

      # Simple cycle: var1 -> var2 -> var3 -> var1
      rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loops = Analyser.find_loops(rels)
      assert length(loops) == 1
      assert MapSet.new(rels, & &1.id) == MapSet.new(hd(loops), & &1.id)
    end

    test "find_loops should find intersecting cycles" do
      user = user()
      session = session(user)
      vars = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = vars

      rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var4,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loops = Analyser.find_loops(rels)
      assert length(loops) == 2
    end

    test "find_loops should handle edge cases" do
      user = user()
      session = session(user)
      vars = Enum.map(1..4, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4] = vars

      # No cycles
      rels1 = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      assert [] == Analyser.find_loops(rels1)

      # Self loop
      rels2 = [
        relationship_with_vote(
          src: var1,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loops = Analyser.find_loops(rels2)
      assert length(loops) == 1
      assert MapSet.new(rels2, & &1.id) == MapSet.new(hd(loops), & &1.id)
    end

    test "can create simple a->b->a loop" do
      user = user()
      session = session(user)

      # Create the two variables for the loop
      [var_a, var_b] = Enum.map(1..2, fn _ -> variable(session: session, user: user) end)

      # Create relationships a->b and b->a
      relationships = [
        relationship_with_vote(
          src: var_a,
          dst: var_b,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var_b,
          dst: var_a,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:influence_relationships)

      # Verify loop was created with both relationships
      assert MapSet.new(relationships, & &1.id) ==
               MapSet.new(loop.influence_relationships, & &1.id)
    end

    test "non-loop relationships return error changeset" do
      user = user()
      session = session(user)

      # Create three variables but don't close the loop
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      relationships =
        variables
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [src, dst] ->
          relationship_with_vote(
            src: src,
            dst: dst,
            session: session,
            user: user,
            vote_type: :direct
          )
        end)

      result = Revelo.Diagrams.create_loop(relationships, actor: user)

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
      session = session(user)

      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create non-sequential relationships that don't form a loop
      relationships = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      result = Revelo.Diagrams.create_loop(relationships, actor: user)

      assert {:error, changeset} = result

      assert [
               %InvalidChanges{
                 message: "Relationships do not form a continuous loop"
               }
             ] = Map.get(changeset, :errors)
    end

    test "rescan creates loops from relationships" do
      user = user()
      session = session(user)

      # Create variables for two different loops
      variables = Enum.map(1..5, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4, var5] = variables

      # First loop: var1 -> var2 -> var3 -> var1
      loop1_rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Second loop: var3 -> var4 -> var5 -> var3
      loop2_rels = [
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var4,
          dst: var5,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var5,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Run the rescan action
      loops = Revelo.Diagrams.rescan_loops!(session.id)

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

    test "rescan returns empty list when no loops exist" do
      user = user()
      session = session(user)

      # Create variables for a linear path (no loops)
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create linear relationships: var1 -> var2 -> var3
      [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Run rescan and verify empty result
      loops = Revelo.Diagrams.rescan_loops!(session.id)
      assert loops == []
    end

    test "rescan excludes loops containing :no_relationship relationships" do
      user = user()
      session = session(user)

      # Create variables for two different loops
      variables = Enum.map(1..5, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4, var5] = variables

      # First loop: var1 -> var2 -> var3 -> var1
      loop1_rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Second loop: var3 -> var4 -> var5 -> var3
      loop2_rels = [
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var4,
          dst: var5,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var5,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Initial scan should find both loops
      loops = Revelo.Diagrams.rescan_loops!(session.id)
      assert length(loops) == 2

      # Override one relationship in first loop to :no_relationship
      rel_to_override = List.first(loop1_rels)
      Revelo.Diagrams.override_relationship_type!(rel_to_override, :no_relationship)

      # Rescan should now only find the second loop
      loops = Revelo.Diagrams.rescan_loops!(session.id)
      assert length(loops) == 1

      # Verify the remaining loop is loop2
      loop_with_rels = Ash.load!(List.first(loops), :influence_relationships)

      assert Enum.all?(
               loop2_rels,
               fn rel1 ->
                 Enum.any?(loop_with_rels.influence_relationships, fn rel2 ->
                   rel1.id == rel2.id
                 end)
               end
             )
    end

    test "rescan finds all loops after adding new relationships" do
      user = user()
      session = session(user)

      # Create three variables
      [var_a, var_b, var_c] = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

      # Create initial simple loop: a->b->a
      initial_loop_rels = [
        relationship_with_vote(
          src: var_a,
          dst: var_b,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var_b,
          dst: var_a,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Initial rescan should find just the a->b->a loop
      initial_loops = Revelo.Diagrams.rescan_loops!(session.id)
      assert length(initial_loops) == 1

      initial_loop = Ash.load!(List.first(initial_loops), :influence_relationships)

      assert MapSet.new(initial_loop_rels, & &1.id) ==
               MapSet.new(initial_loop.influence_relationships, & &1.id)

      # Add new relationships to form a second loop: b->c->a
      [
        relationship_with_vote(
          src: var_b,
          dst: var_c,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var_c,
          dst: var_a,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Rescan should now find both loops
      final_loops = Revelo.Diagrams.rescan_loops!(session.id)
      assert length(final_loops) == 2

      # Verify first loop still exists
      assert Enum.any?(final_loops, fn loop ->
               loop = Ash.load!(loop, :influence_relationships)

               MapSet.new(initial_loop_rels, & &1.id) ==
                 MapSet.new(loop.influence_relationships, & &1.id)
             end)
    end

    test "calling rescan twice in a row doesn't change any of the loops" do
      user = user()
      session = session(user)

      # Create variables for two different loops
      variables = Enum.map(1..5, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3, var4, var5] = variables

      # First loop: var1 -> var2 -> var3 -> var1
      _loop1_rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Second loop: var3 -> var4 -> var5 -> var3
      _loop2_rels = [
        relationship_with_vote(
          src: var3,
          dst: var4,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var4,
          dst: var5,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var5,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Run rescan twice
      loops1 = Revelo.Diagrams.rescan_loops!(session.id)
      loops2 = Revelo.Diagrams.rescan_loops!(session.id)

      # Verify both scans produced same results
      assert length(loops1) == length(loops2)

      loops1_ids = loops1 |> Enum.map(& &1.id) |> Enum.sort()
      loops2_ids = loops2 |> Enum.map(& &1.id) |> Enum.sort()
      assert loops1_ids == loops2_ids

      # Verify relationships in each loop remained the same
      loops1_with_rels =
        Enum.map(loops1, fn l ->
          Ash.load!(l, :influence_relationships).influence_relationships
        end)

      loops2_with_rels =
        Enum.map(loops2, fn l ->
          Ash.load!(l, :influence_relationships).influence_relationships
        end)

      assert length(loops1_with_rels) == length(loops2_with_rels)

      for loop1_rels <- loops1_with_rels do
        assert Enum.any?(loops2_with_rels, fn loop2_rels ->
                 rel_ids1 = MapSet.new(loop1_rels, & &1.id)
                 rel_ids2 = MapSet.new(loop2_rels, & &1.id)
                 MapSet.equal?(rel_ids1, rel_ids2)
               end)
      end
    end

    test "can create self-loop" do
      user = user()
      session = session(user)

      # Create a single variable for the self-loop
      variable = variable(session: session, user: user)

      # Create relationship from variable to itself
      relationship =
        relationship_with_vote(
          src: variable,
          dst: variable,
          session: session,
          user: user,
          vote_type: :direct
        )

      loop =
        [relationship]
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:influence_relationships)

      # Verify loop was created with the self-referential relationship
      assert [relationship_id] = Enum.map(loop.influence_relationships, & &1.id)
      assert relationship_id == relationship.id
    end

    test "loops_equal? correctly compares loops" do
      user = user()
      session = session(user)

      # Create test variables
      variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)
      [var1, var2, var3] = variables

      # Create a simple loop: var1 -> var2 -> var3 -> var1
      loop_rels = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      # Create the same loop but starting from a different point
      rotated_loop = Enum.drop(loop_rels, 1) ++ [List.first(loop_rels)]

      # Different loop with same variables
      different_loop = [
        relationship_with_vote(
          src: var1,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
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

  describe "calculating loop type" do
    test "returns :direct for 2-node even graph where all relationships are direct" do
      user = user()
      session = session(user)

      var1 = variable(session: session, user: user)
      var2 = variable(session: session, user: user)

      relationships = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!([:influence_relationships, :type])

      assert loop.type == :reinforcing
    end

    test "returns :inverse for 3-node loop with 2 reinforcing and 1 inverse relationship" do
      user = user()
      session = session(user)

      var1 = variable(session: session, user: user)
      var2 = variable(session: session, user: user)
      var3 = variable(session: session, user: user)

      relationships = [
        relationship_with_vote(
          src: var1,
          dst: var2,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :inverse
        )
      ]

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:type)

      assert loop.type == :balancing
    end

    test "returns :conflicting when at least one relationship has both inverse and direct votes" do
      user = user()
      session = session(user)

      var1 = variable(session: session, user: user)
      var2 = variable(session: session, user: user)
      var3 = variable(session: session, user: user)

      # Create first relationship with both types of votes
      first_rel = relationship(src: var1, dst: var2, session: session, user: user)
      Revelo.Diagrams.relationship_vote!(first_rel, :direct, actor: user)
      user2 = user()
      Revelo.Diagrams.relationship_vote!(first_rel, :inverse, actor: user2)

      relationships = [
        Ash.load!(first_rel, :type),
        relationship_with_vote(
          src: var2,
          dst: var3,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var3,
          dst: var1,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(actor: user)
        |> Ash.load!(:type)

      assert loop.type == :conflicting
    end
  end
end
