defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Relationship
  alias Revelo.Diagrams.RelationshipVote

  describe "relationship actions" do
    property "succeeds on all valid create input" do
      user = user()
      session = session()
      src = variable(session: session, user: user)
      dst = variable(session: session, user: user)

      check all(input <- Ash.Generator.action_input(Relationship, :create)) do
        input =
          input
          |> Map.put(:session, session)
          |> Map.put(:src, src)
          |> Map.put(:dst, dst)

        rel =
          Relationship
          |> Ash.Changeset.for_create(:create, input, actor: user)
          |> Ash.create!()

        assert rel.src_id == src.id
        assert rel.dst_id == dst.id
      end
    end

    test "can create relationship using generator" do
      relationship = Ash.load!(relationship(), [:src, :dst, :session])

      assert relationship
      assert relationship.session
      assert relationship.src
      assert relationship.dst
    end

    test "can create relationship vote" do
      user = user()
      session = session()
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      vote =
        RelationshipVote
        |> Ash.Changeset.for_create(:create, %{relationship: relationship}, actor: user)
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
        |> Ash.Changeset.for_create(:create, %{relationship: relationship1}, actor: user)
        |> Ash.create!()

      vote2 =
        RelationshipVote
        |> Ash.Changeset.for_create(:create, %{relationship: relationship2}, actor: user)
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
  end
end
