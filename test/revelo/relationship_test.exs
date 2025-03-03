defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Ash.Error.Invalid
  alias Revelo.Diagrams.Relationship
  alias Revelo.Diagrams.RelationshipVote

  describe "relationship actions" do
    test "succeeds on valid create input" do
      user = user()
      session = session(user)
      src = variable(session: session, user: user)
      dst = variable(session: session, user: user)

      input = %{session: session, src: src, dst: dst}

      rel =
        Relationship
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create!()

      assert rel.src_id == src.id
      assert rel.dst_id == dst.id
    end

    test "can create relationship using generator" do
      relationship = Ash.load!(relationship(), [:src, :dst, :session])

      assert relationship
      assert relationship.session
      assert relationship.src
      assert relationship.dst
    end

    test "get with unique_relationship identity" do
      user = user()
      session = session(user)
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)

      rel = relationship(user: user, session: session, src: src, dst: dst)

      # Look up using unique identity
      found_rel = Ash.get!(Relationship, src_id: src.id, dst_id: dst.id)

      assert found_rel.id == rel.id
    end

    test "Revelo.Diagrams.list_potential_relationships! returns all relationships" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      rel1 = relationship(user: user, session: session, src: var1, dst: var2)
      rel2 = relationship(user: user, session: session, src: var2, dst: var1)

      relationships = Revelo.Diagrams.list_potential_relationships!(session.id)

      assert rel1.id in Enum.map(relationships, & &1.id)
      assert rel2.id in Enum.map(relationships, & &1.id)
    end

    test "list_relationships_from_src! returns all relationships from a source variable" do
      user = user()
      session = session(user)
      src = variable(user: user, session: session)
      dst1 = variable(user: user, session: session)
      dst2 = variable(user: user, session: session)

      # Create relationships from the source to multiple destinations
      rel1 = relationship(user: user, session: session, src: src, dst: dst1)
      rel2 = relationship(user: user, session: session, src: src, dst: dst2)

      # Create a relationship in the opposite direction
      rel3 = relationship(user: user, session: session, src: dst1, dst: src)

      # List relationships from the source
      relationships = Revelo.Diagrams.list_relationships_from_src!(src.id)

      # Should return relationships where src is the source
      assert length(relationships) == 2
      rel_ids = Enum.map(relationships, & &1.id)
      assert rel1.id in rel_ids
      assert rel2.id in rel_ids
      refute rel3.id in rel_ids

      # Verify relationships are sorted by voted? attribute with nil values first
      assert is_nil(hd(relationships).voted?)

      if length(relationships) > 1 do
        assert is_nil(hd(relationships).voted?) || !is_nil(List.last(relationships).voted?)
      end
    end

    test "no duplicate relationships" do
      user = user()
      session = session(user)
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)

      _r1 = relationship(user: user, session: session, src: src, dst: dst)

      assert_raise Invalid, fn ->
        relationship(user: user, session: session, src: src, dst: dst)
      end
    end

    test "can create relationship vote" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      relationship = Ash.load!(relationship, :voted?, actor: user)
      refute relationship.voted?

      vote =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship,
            type: :direct
          },
          actor: user
        )
        |> Ash.create!()

      assert vote.voter_id == user.id
      assert vote.relationship_id == relationship.id

      relationship = Ash.load!(relationship, :voted?, actor: user)
      assert relationship.voted?
    end

    test "relationship_with_vote generator sets type attribute" do
      relationship =
        Ash.load!(
          relationship_with_vote(vote_type: :direct),
          [:type]
        )

      assert relationship.type == :direct

      relationship =
        Ash.load!(
          relationship_with_vote(vote_type: :inverse),
          [:type]
        )

      assert relationship.type == :inverse
    end

    test "can override relationship type" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      # Vote direct initially
      Revelo.Diagrams.relationship_vote!(relationship, :direct, actor: user)
      relationship = Ash.load!(relationship, [:type])
      assert relationship.type == :direct

      # Override to inverse
      relationship = Revelo.Diagrams.override_relationship_type!(relationship, :inverse)
      relationship = Ash.load!(relationship, [:type])
      assert relationship.type == :inverse

      # Verify votes are still present but override takes precedence
      relationship = Ash.load!(relationship, [:type, :direct_votes, :inverse_votes])
      assert relationship.direct_votes == 1
      assert relationship.inverse_votes == 0
      assert relationship.type == :inverse
    end

    test "override_type fails if type isn't one of direct/inverse/no_relationship" do
      relationship = relationship()

      assert_raise Invalid, fn ->
        Revelo.Diagrams.override_relationship_type!(relationship, :invalid_type)
      end
    end

    test "relationship_vote upserts the type when user votes again" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      # Create initial vote
      vote1 = Revelo.Diagrams.relationship_vote!(relationship, :direct, actor: user)

      # Vote again with different type
      vote2 = Revelo.Diagrams.relationship_vote!(relationship, :inverse, actor: user)

      # Should have same composite key values but updated type
      assert vote1.voter_id == vote2.voter_id
      assert vote1.relationship_id == vote2.relationship_id
      assert vote1.type == :direct
      assert vote2.type == :inverse

      # Verify only one vote exists
      relationship = Ash.load!(relationship, :votes)
      assert length(relationship.votes) == 1
      assert hd(relationship.votes).type == :inverse
    end

    test "can create votes for multiple relationships with same user" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      var3 = variable(user: user, session: session)

      relationship1 = relationship(user: user, session: session, src: var1, dst: var2)
      relationship2 = relationship(user: user, session: session, src: var2, dst: var3)

      vote1 =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship1,
            type: :direct
          },
          actor: user
        )
        |> Ash.create!()

      vote2 =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship2,
            type: :direct
          },
          actor: user
        )
        |> Ash.create!()

      assert vote1.voter_id == user.id
      assert vote2.voter_id == user.id
      assert vote1.relationship_id == relationship1.id
      assert vote2.relationship_id == relationship2.id

      relationship1 = Ash.load!(relationship1, :votes)
      relationship2 = Ash.load!(relationship2, :votes)
      relationship1_id = relationship1.id
      relationship2_id = relationship2.id
      assert [%{relationship_id: ^relationship1_id}] = relationship1.votes
      assert [%{relationship_id: ^relationship2_id}] = relationship2.votes
    end

    test "multiple users can vote on same relationship" do
      user1 = user()
      user2 = user()
      session = session(user1)
      var1 = variable(user: user1, session: session)
      var2 = variable(user: user1, session: session)
      relationship = relationship(user: user1, session: session, src: var1, dst: var2)

      vote1 =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship,
            type: :direct
          },
          actor: user1
        )
        |> Ash.create!()

      vote2 =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship,
            type: :direct
          },
          actor: user2
        )
        |> Ash.create!()

      assert vote1.voter_id == user1.id
      assert vote2.voter_id == user2.id
      assert vote1.relationship_id == relationship.id
      assert vote2.relationship_id == relationship.id

      relationship = Ash.load!(relationship, :votes)
      assert length(relationship.votes) == 2
    end

    test "list_relationship_votes returns all votes sorted by source/dest variable name" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session, name: "A")
      var2 = variable(user: user, session: session, name: "B")
      var3 = variable(user: user, session: session, name: "C")

      rel1 = relationship(user: user, session: session, src: var2, dst: var3)
      rel2 = relationship(user: user, session: session, src: var1, dst: var2)
      rel3 = relationship(user: user, session: session, src: var1, dst: var3)

      vote1 = Revelo.Diagrams.relationship_vote!(rel1, :direct, actor: user)
      vote2 = Revelo.Diagrams.relationship_vote!(rel2, :inverse, actor: user)
      vote3 = Revelo.Diagrams.relationship_vote!(rel3, :direct, actor: user)

      votes = Revelo.Diagrams.list_relationship_votes!(session.id)

      assert Enum.map(votes, fn v -> {v.relationship_id, v.voter_id} end) == [
               {vote2.relationship_id, vote2.voter_id},
               {vote3.relationship_id, vote3.voter_id},
               {vote1.relationship_id, vote1.voter_id}
             ]

      relationships = Revelo.Diagrams.list_potential_relationships!(session.id)

      rel1 = Enum.find(relationships, &(&1.id == rel1.id))
      rel2 = Enum.find(relationships, &(&1.id == rel2.id))
      rel3 = Enum.find(relationships, &(&1.id == rel3.id))

      assert rel1.direct_votes == 1
      assert rel1.inverse_votes == 0
      assert rel1.no_relationship_votes == 0
      assert rel2.direct_votes == 0
      assert rel2.inverse_votes == 1
      assert rel2.no_relationship_votes == 0
      assert rel3.direct_votes == 1
      assert rel3.inverse_votes == 0
      assert rel3.no_relationship_votes == 0
    end

    test "hidden variables hide relationships from list_potential_relationships" do
      user = user()
      session = session(user)
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)
      rel = relationship(user: user, session: session, src: src, dst: dst)

      # Before hiding, relationship should be listed
      relationships = Revelo.Diagrams.list_potential_relationships!(session.id)
      assert rel.id in Enum.map(relationships, & &1.id)

      # After hiding src, relationship should not be listed
      Revelo.Diagrams.hide_variable!(src)
      relationships = Revelo.Diagrams.list_potential_relationships!(session.id)
      refute rel.id in Enum.map(relationships, & &1.id)

      # Unhide src and hide dst instead
      Revelo.Diagrams.unhide_variable!(src)
      Revelo.Diagrams.hide_variable!(dst)
      relationships = Revelo.Diagrams.list_potential_relationships!(session.id)
      refute rel.id in Enum.map(relationships, & &1.id)
    end

    test "enumerate_relationships creates all src->dst relationships" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      var3 = variable(user: user, session: session)

      relationships = Revelo.Diagrams.enumerate_relationships!(session)

      assert length(relationships) == 6

      # verify all combinations are present
      rel_pairs =
        MapSet.new(relationships, fn rel -> {rel.src_id, rel.dst_id} end)

      expected_pairs =
        MapSet.new([
          {var1.id, var2.id},
          {var1.id, var3.id},
          {var2.id, var1.id},
          {var2.id, var3.id},
          {var3.id, var1.id},
          {var3.id, var2.id}
        ])

      assert rel_pairs == expected_pairs

      # check the same invariants with four variables
      var4 = variable(user: user, session: session)

      relationships = Revelo.Diagrams.enumerate_relationships!(session)

      assert length(relationships) == 12

      rel_pairs =
        MapSet.new(relationships, fn rel -> {rel.src_id, rel.dst_id} end)

      expected_pairs =
        MapSet.new([
          {var1.id, var2.id},
          {var1.id, var3.id},
          {var1.id, var4.id},
          {var2.id, var1.id},
          {var2.id, var3.id},
          {var2.id, var4.id},
          {var3.id, var1.id},
          {var3.id, var2.id},
          {var3.id, var4.id},
          {var4.id, var1.id},
          {var4.id, var2.id},
          {var4.id, var3.id}
        ])

      assert rel_pairs == expected_pairs
    end

    test "list_actual_relationships! returns all relationships with at least one direct or inverse vote" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      var3 = variable(user: user, session: session)

      # Create relationships with different vote combinations
      rel1 = relationship(user: user, session: session, src: var1, dst: var2)
      Revelo.Diagrams.relationship_vote!(rel1, :direct, actor: user)

      rel2 = relationship(user: user, session: session, src: var2, dst: var3)
      Revelo.Diagrams.relationship_vote!(rel2, :inverse, actor: user)

      rel3 = relationship(user: user, session: session, src: var1, dst: var3)
      Revelo.Diagrams.relationship_vote!(rel3, :no_relationship, actor: user)

      relationships = Revelo.Diagrams.list_actual_relationships!(session.id)

      assert length(relationships) == 2
      rel_ids = Enum.map(relationships, & &1.id)
      assert rel1.id in rel_ids
      assert rel2.id in rel_ids
      refute rel3.id in rel_ids
    end

    test "type calculation" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      # Test no votes case
      relationship = Ash.load!(relationship, [:type])
      assert relationship.type == :no_relationship

      # Test direct only case
      Revelo.Diagrams.relationship_vote!(relationship, :direct, actor: user)

      relationship = Ash.load!(relationship, [:type])
      assert relationship.type == :direct

      # Create another user and add inverse vote to test conflicting case
      user2 = user()
      Revelo.Diagrams.relationship_vote!(relationship, :inverse, actor: user2)

      relationship = Ash.load!(relationship, [:type])
      assert relationship.type == :conflicting

      # Create a new relationship to test inverse only case
      relationship2 = relationship(user: user, session: session, src: var2, dst: var1)
      Revelo.Diagrams.relationship_vote!(relationship2, :inverse, actor: user)

      relationship2 = Ash.load!(relationship2, [:type])
      assert relationship2.type == :inverse
    end

    test "list_conflicting_relationships! returns all conflicting relationships" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      var3 = variable(user: user, session: session)

      # Create relationship with conflicting votes
      rel1 = relationship(user: user, session: session, src: var1, dst: var2)
      Revelo.Diagrams.relationship_vote!(rel1, :direct, actor: user)
      Revelo.Diagrams.relationship_vote!(rel1, :inverse, actor: user())

      # Create relationship with only direct vote
      rel2 = relationship(user: user, session: session, src: var2, dst: var3)
      Revelo.Diagrams.relationship_vote!(rel2, :direct, actor: user)

      # Create relationship with only inverse vote
      rel3 = relationship(user: user, session: session, src: var1, dst: var3)
      Revelo.Diagrams.relationship_vote!(rel3, :inverse, actor: user)

      relationships = Revelo.Diagrams.list_conflicting_relationships!(session.id)

      assert length(relationships) == 1
      [conflicting] = relationships
      assert conflicting.id == rel1.id
      assert conflicting.direct_votes > 0
      assert conflicting.inverse_votes > 0
      assert conflicting.type == :conflicting
    end
  end
end
