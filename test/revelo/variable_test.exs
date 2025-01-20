defmodule Revelo.VariableTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Variable
  alias Revelo.Diagrams.VariableVote

  describe "variable actions" do
    property "accepts valid create input" do
      user = user()
      session = session()

      check all(
              input <-
                Ash.Generator.action_input(Variable, :create)
            ) do
        input = Map.put(input, :session, session)

        changeset =
          Ash.Changeset.for_create(Variable, :create, input, actor: user)

        assert changeset.valid?
      end
    end

    property "succeeds on all valid create input" do
      user = user()
      session = session()

      check all(input <- Ash.Generator.action_input(Variable, :create)) do
        input = Map.put(input, :session, session)

        var =
          Variable
          |> Ash.Changeset.for_create(:create, input, actor: user)
          |> Ash.create!()

        assert var.creator.id == user.id
      end
    end

    test "can create variable" do
      variable = variable()

      assert variable
      assert variable.session
      assert variable.creator
    end
  end

  describe "variable vote actions" do
    test "can create variable vote" do
      user = generate(user())
      variable = generate(variable(user: user))

      vote =
        VariableVote
        |> Ash.Changeset.for_create(:create, %{variable: variable}, actor: user)
        |> Ash.create!()

      assert vote.voter_id == user.id
      assert vote.variable_id == variable.id
    end

    test "multiple users can vote on same variable" do
      user1 = generate(user())
      user2 = generate(user())
      variable = generate(variable(user: user1))

      vote1 =
        VariableVote
        |> Ash.Changeset.for_create(:create, %{variable: variable}, actor: user1)
        |> Ash.create!()

      vote2 =
        VariableVote
        |> Ash.Changeset.for_create(:create, %{variable: variable}, actor: user2)
        |> Ash.create!()

      assert vote1.voter_id == user1.id
      assert vote2.voter_id == user2.id
      assert vote1.variable_id == variable.id
      assert vote2.variable_id == variable.id

      variable = Ash.load!(variable, :votes)
      assert length(variable.votes) == 2
    end

    # test "cannot vote twice" do
    #   user = generate(user())
    #   variable = generate(variable(user: user))

    #   vote_changeset = fn ->
    #     VariableVote
    #     |> Ash.Changeset.new()
    #     |> Ash.Changeset.set_argument(:voter_id, user.id)
    #     |> Ash.Changeset.set_argument(:variable_id, variable.id)
    #   end

    #   Ash.create!(vote_changeset.())

    #   assert_raise(
    #     Ash.Error.Invalid,
    #     ~r/unique_vote/,
    #     fn -> Ash.create!(vote_changeset.()) end
    #   )
    # end
  end
end
