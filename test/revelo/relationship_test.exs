defmodule Revelo.RelationshipTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Relationship

  describe "relationship actions" do
    property "accepts valid create input" do
      user = generate(user())

      check all(input <- Ash.Generator.action_input(Relationship, :create)) do
        changeset =
          Ash.Changeset.for_create(Relationship, :create, input, actor: user)

        assert changeset.valid?
      end
    end

    property "succeeds on all valid create input" do
      user = generate(user())
      session = generate(session(user: user))
      src = generate(variable(session: session, user: user))
      dst = generate(variable(session: session, user: user))

      check all(input <- Ash.Generator.action_input(Relationship, :create)) do
        input =
          input
          |> Map.put(:session_id, session.id)
          |> Map.put(:src_id, src.id)
          |> Map.put(:dst_id, dst.id)

        rel =
          Relationship
          |> Ash.Changeset.for_create(:create, input, actor: user)
          |> Ash.create!()

        assert rel.src_id == src.id
        assert rel.dst_id == dst.id
      end
    end

    test "can create relationship" do
      relationship = relationship() |> generate() |> Ash.load!([:src, :dst, :session])

      assert relationship
      assert relationship.session
      assert relationship.src
      assert relationship.dst
    end
  end
end
