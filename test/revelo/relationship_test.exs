defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ReveloTest.Generators

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

    test "Revelo.Diagrams.list! returns only unhidden relationships" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      visible_rel = relationship(user: user, session: session, src: var1, dst: var2)
      hidden_rel = relationship(user: user, session: session, src: var2, dst: var1)

      hidden_rel = Revelo.Diagrams.hide_relationship!(hidden_rel)
      assert hidden_rel.hidden? == true

      relationships = Revelo.Diagrams.list_relationships!(session.id)

      assert visible_rel.id in Enum.map(relationships, & &1.id)
      refute hidden_rel.id in Enum.map(relationships, & &1.id)

      # check that the hidden relationship is returned when include_hidden is true
      relationships = Revelo.Diagrams.list_relationships!(session.id, true)

      assert visible_rel.id in Enum.map(relationships, & &1.id)
      assert hidden_rel.id in Enum.map(relationships, & &1.id)
    end

    test "no duplicate relationships" do
      user = user()
      session = session(user)
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)

      _r1 = relationship(user: user, session: session, src: src, dst: dst)

      assert_raise Ash.Error.Invalid, fn ->
        relationship(user: user, session: session, src: src, dst: dst)
      end
    end

    test "can create relationship vote" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      vote =
        RelationshipVote
        |> Ash.Changeset.for_create(
          :create,
          %{
            relationship: relationship,
            type: :reinforcing
          },
          actor: user
        )
        |> Ash.create!()

      assert vote.voter_id == user.id
      assert vote.relationship_id == relationship.id
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
            type: :reinforcing
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
            type: :reinforcing
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
            type: :reinforcing
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
            type: :reinforcing
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

      vote1 = Revelo.Diagrams.relationship_vote!(rel1, :reinforcing, actor: user)
      vote2 = Revelo.Diagrams.relationship_vote!(rel2, :balancing, actor: user)
      vote3 = Revelo.Diagrams.relationship_vote!(rel3, :reinforcing, actor: user)

      votes = Revelo.Diagrams.list_relationship_votes!(session.id)

      assert Enum.map(votes, fn v -> {v.relationship_id, v.voter_id} end) == [
               {vote2.relationship_id, vote2.voter_id},
               {vote3.relationship_id, vote3.voter_id},
               {vote1.relationship_id, vote1.voter_id}
             ]

      relationships = Revelo.Diagrams.list_relationships!(session.id)

      rel1 = Enum.find(relationships, &(&1.id == rel1.id))
      rel2 = Enum.find(relationships, &(&1.id == rel2.id))
      rel3 = Enum.find(relationships, &(&1.id == rel3.id))

      assert rel1.reinforcing_votes == 1
      assert rel1.balancing_votes == 0
      assert rel1.no_relationship_votes == 0
      assert rel2.reinforcing_votes == 0
      assert rel2.balancing_votes == 1
      assert rel2.no_relationship_votes == 0
      assert rel3.reinforcing_votes == 1
      assert rel3.balancing_votes == 0
      assert rel3.no_relationship_votes == 0
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

    test "type calculation" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      # Test no votes case
      relationship =
        Ash.load!(relationship, [
          :reinforcing_votes,
          :balancing_votes,
          :no_relationship_votes,
          :type
        ])

      assert relationship.type == "no_relationship"

      # Test reinforcing only case
      Revelo.Diagrams.relationship_vote!(relationship, :reinforcing, actor: user)

      relationship =
        Ash.load!(relationship, [
          :reinforcing_votes,
          :balancing_votes,
          :no_relationship_votes,
          :type
        ])

      assert relationship.type == "reinforcing"

      # Create another user and add balancing vote to test conflicting case
      user2 = user()
      Revelo.Diagrams.relationship_vote!(relationship, :balancing, actor: user2)

      relationship =
        Ash.load!(relationship, [
          :reinforcing_votes,
          :balancing_votes,
          :no_relationship_votes,
          :type
        ])

      assert relationship.type == "conflicting"

      # Create a new relationship to test balancing only case
      relationship2 = relationship(user: user, session: session, src: var2, dst: var1)
      Revelo.Diagrams.relationship_vote!(relationship2, :balancing, actor: user)

      relationship2 =
        Ash.load!(relationship2, [
          :reinforcing_votes,
          :balancing_votes,
          :no_relationship_votes,
          :type
        ])

      assert relationship2.type == "balancing"
    end

    test "list_conflicting_relationships returns only conflicting relationships" do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      var3 = variable(user: user, session: session)

      # Create a relationship with conflicting votes
      rel1 = relationship(user: user, session: session, src: var1, dst: var2)
      Revelo.Diagrams.relationship_vote!(rel1, :reinforcing, actor: user)
      Revelo.Diagrams.relationship_vote!(rel1, :balancing, actor: user())

      # Create a relationship with only reinforcing votes
      rel2 = relationship(user: user, session: session, src: var2, dst: var3)
      Revelo.Diagrams.relationship_vote!(rel2, :reinforcing, actor: user)

      rel1 = Ash.load!(rel1, [:type])
      rel2 = Ash.load!(rel2, [:type])

      assert rel1.type == "conflicting"
      assert rel2.type == "reinforcing"

      conflicting = Revelo.Diagrams.list_conflicting_relationships!(session.id)
      assert length(conflicting) == 1
      assert hd(conflicting).id == rel1.id
    end
  end
end
