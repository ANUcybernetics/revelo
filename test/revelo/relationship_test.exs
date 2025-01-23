defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Revelo.Diagrams.Relationship
  alias Revelo.Diagrams.RelationshipVote

  describe "relationship actions" do
    test "succeeds on valid create input" do
      user = user()
      session = session()
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
      session = session()
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)

      rel = relationship(user: user, session: session, src: src, dst: dst)

      # Look up using unique identity
      found_rel = Ash.get!(Relationship, src_id: src.id, dst_id: dst.id)

      assert found_rel.id == rel.id
    end

    test "Revelo.Diagrams.list! returns only unhidden relationships" do
      user = user()
      session = session()
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
      session = session()
      src = variable(user: user, session: session)
      dst = variable(user: user, session: session)

      _r1 = relationship(user: user, session: session, src: src, dst: dst)

      assert_raise Ash.Error.Invalid, fn ->
        relationship(user: user, session: session, src: src, dst: dst)
      end
    end

    test "can create relationship vote" do
      user = user()
      session = session()
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
      session = session()
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
      user1 = generate(user())
      user2 = generate(user())
      session = session()
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
  end
end
