defmodule Revelo.VariableTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Ash.Error.Invalid
  alias Revelo.Diagrams.Variable
  alias Revelo.Diagrams.VariableVote

  describe "property-based variable tests" do
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
  end

  describe "variable actions" do
    test "can create variable" do
      variable = variable()

      assert variable
      assert variable.session
      assert variable.creator
    end

    test "can rename variable" do
      variable = variable()
      new_name = "new name"

      renamed_var =
        variable
        |> Ash.Changeset.for_update(:rename, %{name: new_name})
        |> Ash.update!()

      assert renamed_var.name == new_name
    end

    test "can toggle key flag on variable" do
      variable = variable()
      assert variable.is_key? == false

      variable = Revelo.Diagrams.set_key_variable!(variable)
      assert variable.is_key? == true

      variable = Revelo.Diagrams.unset_key_variable!(variable)
      assert variable.is_key? == false
    end

    test "can toggle hidden flag on variable" do
      variable = variable()
      assert variable.hidden? == false

      variable = Revelo.Diagrams.hide_variable!(variable)
      assert variable.hidden? == true

      variable = Revelo.Diagrams.unhide_variable!(variable)
      assert variable.hidden? == false
    end

    test "Revelo.Diagrams.list! returns only unhidden variables" do
      user = user()
      session = session()
      visible_var = variable(user: user, session: session)
      hidden_var = variable(user: user, session: session)

      hidden_var = Revelo.Diagrams.hide_variable!(hidden_var)
      assert hidden_var.hidden? == true

      variables = Revelo.Diagrams.list_variables!(session.id)

      assert visible_var.id in Enum.map(variables, & &1.id)
      refute hidden_var.id in Enum.map(variables, & &1.id)

      # check that the hidden variable is returned when include_hidden is true
      variables = Revelo.Diagrams.list_variables!(session.id, true)

      assert visible_var.id in Enum.map(variables, & &1.id)
      assert hidden_var.id in Enum.map(variables, & &1.id)
    end

    test "enforces uniqueness of names within session" do
      user = user()
      session = session()

      input = %{name: "test", session: session}

      _variable1 =
        Variable
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create!()

      assert_raise Invalid, fn ->
        Variable
        |> Ash.Changeset.for_create(:create, input, actor: user)
        |> Ash.create!()
      end
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

    test "cannot vote twice" do
      user = user()
      variable = variable(user: user)

      _vote =
        VariableVote
        |> Ash.Changeset.for_create(:create, %{variable: variable}, actor: user)
        |> Ash.create!()

      assert_raise Invalid, fn ->
        VariableVote
        |> Ash.Changeset.for_create(:create, %{variable: variable}, actor: user)
        |> Ash.create!()
      end

      variable = Ash.load!(variable, :votes)
      assert [%{voter_id: voter_id, variable_id: variable_id}] = variable.votes
      assert voter_id == user.id
      assert variable_id == variable.id
    end

    test "can vote using vote code interface" do
      user = user()
      variable = variable(user: user)

      Revelo.Diagrams.variable_vote!(variable, actor: user)

      variable = Ash.load!(variable, :votes)
      assert [%{voter_id: voter_id, variable_id: variable_id}] = variable.votes
      assert voter_id == user.id
      assert variable_id == variable.id
    end

    test "list_variable_votes shows all votes sorted by variable name" do
      user1 = user()
      user2 = user()
      session = session()
      variable1 = variable(name: "abc", user: user1, session: session)
      variable2 = variable(name: "xyz", user: user1, session: session)

      Revelo.Diagrams.variable_vote!(variable2, actor: user1)
      Revelo.Diagrams.variable_vote!(variable1, actor: user1)
      Revelo.Diagrams.variable_vote!(variable1, actor: user2)

      votes = Revelo.Diagrams.list_variable_votes!(session.id)

      assert length(votes) == 3
      assert Enum.map(votes, & &1.variable_id) == [variable1.id, variable1.id, variable2.id]

      assert votes |> Enum.map(& &1.voter_id) |> Enum.sort() ==
               Enum.sort([user1.id, user1.id, user2.id])
    end
  end
end
