defmodule Revelo.VariableTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Variable

  describe "variable actions" do
    property "accepts valid create input" do
      user = generate(user())

      check all(input <- Ash.Generator.action_input(Variable, :create)) do
        changeset =
          Ash.Changeset.for_create(Variable, :create, input, actor: user)

        assert changeset.valid?
      end
    end

    property "succeeds on all valid create input" do
      user = generate(user())
      session = generate(session())

      check all(input <- Ash.Generator.action_input(Variable, :create)) do
        input = Map.put(input, :session_id, session.id)

        var =
          Variable
          |> Ash.Changeset.for_create(:create, input, actor: user)
          |> Ash.create!()

        assert var.creator.id == user.id
      end
    end

    test "can create variable" do
      # variable() |> pick() |> dbg()
      variable = generate(variable())

      assert variable
    end
  end
end
