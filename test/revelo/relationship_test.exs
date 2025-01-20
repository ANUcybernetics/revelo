defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Relationship

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
  end
end
