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
      session = session(user)

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
      session = session(user)

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

    test "can destroy variable" do
      variable = variable()

      variable
      |> Ash.Changeset.for_destroy(:destroy)
      |> Ash.destroy!()

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(Variable, variable.id)
      end

      variable = variable()
      Revelo.Diagrams.destroy_variable!(variable)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(Variable, variable.id)
      end
    end

    test "can toggle key flag on variable" do
      variable = variable()
      assert variable.is_voi? == false

      variable = Revelo.Diagrams.toggle_voi!(variable)
      assert variable.is_voi? == true

      variable = Revelo.Diagrams.toggle_voi!(variable)
      assert variable.is_voi? == false
    end

    test "can get variable of interest from session" do
      user = user()
      session = session(user)
      variable1 = variable(user: user, session: session)
      variable2 = variable(user: user, session: session)

      # Make variable2 a variable of interest
      variable2 = Revelo.Diagrams.toggle_voi!(variable2)
      assert variable2.is_voi? == true

      voi = Revelo.Diagrams.get_voi!(session.id)
      assert voi.id == variable2.id

      # Toggle key off, should error when trying to get
      Revelo.Diagrams.toggle_voi!(variable2)

      assert_raise Ash.Error.Query.NotFound, fn ->
        Revelo.Diagrams.get_voi!(session.id)
      end

      # Toggle key on for variable1, should get new key
      variable1 = Revelo.Diagrams.toggle_voi!(variable1)
      assert variable1.is_voi? == true

      voi = Revelo.Diagrams.get_voi!(session.id)
      assert voi.id == variable1.id
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
      session = session(user)
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

    test "variable of interest is returned first by list_variables!" do
      user = user()
      session = session(user)
      variable1 = variable(name: "abc", user: user, session: session)
      variable2 = variable(name: "xyz", user: user, session: session)

      # Make variable2 a variable of interest even though it's later alphabetically
      variable2 = Revelo.Diagrams.toggle_voi!(variable2)
      assert variable2.is_voi? == true

      variables = Revelo.Diagrams.list_variables!(session.id)
      assert length(variables) == 2

      [first, second] = variables
      assert first.id == variable2.id
      assert second.id == variable1.id
    end

    test "toggling variable of interest on unsets other variables of interest in the session" do
      user = user()
      session = session(user)
      variable1 = variable(user: user, session: session)
      variable2 = variable(user: user, session: session)

      variable1 = Revelo.Diagrams.toggle_voi!(variable1)
      assert variable1.is_voi? == true

      variable2 = Revelo.Diagrams.toggle_voi!(variable2)
      assert variable2.is_voi? == true

      variable1 = Ash.get!(Variable, variable1.id)
      assert variable1.is_voi? == false
    end

    test "enforces uniqueness of names within session" do
      user = user()
      session = session(user)

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
      session = session(user1)
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

      variable1 = Ash.load!(variable1, :vote_tally)
      variable2 = Ash.load!(variable2, :vote_tally)

      assert variable1.vote_tally == 2
      assert variable2.vote_tally == 1
    end

    test "voted? calculation works" do
      user = user()
      variable = variable(user: user)

      variable = Ash.load!(variable, [:voted?], actor: user)
      refute variable.voted?

      Revelo.Diagrams.variable_vote!(variable, actor: user)

      variable = Ash.load!(variable, [:voted?], actor: user)
      assert variable.voted?

      other_user = user()
      variable = Ash.load!(variable, [:voted?], actor: other_user)
      refute variable.voted?
    end
  end
end
