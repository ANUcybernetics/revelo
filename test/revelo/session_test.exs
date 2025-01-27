defmodule Revelo.SessionTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Accounts.User
  alias Revelo.Sessions.Session
  alias Revelo.Sessions.SessionParticipants

  describe "session actions" do
    property "accepts valid create input" do
      check all(input <- Ash.Generator.action_input(Session, :create)) do
        changeset = Ash.Changeset.for_create(Session, :create, input)
        assert changeset.valid?
      end
    end

    property "succeeds on all valid create input" do
      check all(input <- Ash.Generator.action_input(Session, :create)) do
        Session |> Ash.Changeset.for_create(:create, input) |> Ash.create!()
      end
    end

    test "overrides passed through to generator work properly" do
      user = user()
      session = session()
      variable = variable(user: user, session: session)
      assert variable.creator == user
      assert variable.session == session
    end

    test "can create session with participants" do
      session = session()
      user = user()
      user2 = user()

      # TODO update this when the auth/policies stuff is in place
      Ash.get!(User, user.id, authorize?: false)

      session =
        session
        |> Ash.Changeset.for_update(:add_participant, %{participant: user})
        |> Ash.update!()

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 1

      assert session.participants == [user]

      # add a second user
      session =
        session
        |> Ash.Changeset.for_update(:add_participant, %{participant: user2})
        |> Ash.update!()
        # |> Ash.load!(:participants, actor: user)
        |> Ash.load!(:participants, authorize?: false)

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 2
      assert length(session.participants) == 2
      assert Enum.map(session.participants, & &1.id) == [user.id, user2.id]
    end

    test "can add participant as facilitator" do
      session = session()
      user = user()

      session =
        session
        |> Ash.Changeset.for_update(:add_participant, %{participant: user, facilitator: true})
        |> Ash.update!()
        |> Ash.load!(:participants, authorize?: false)

      session_participant = Ash.get!(Revelo.Sessions.SessionParticipants, session_id: session.id, participant_id: user.id)

      # |> Ash.Changeset.for_update(:set_as_facilitator)
      # |> Ash.update!()

      assert session_participant.facilitator == true
      assert length(session.participants) == 1
      assert hd(session.participants).id == user.id
    end

    test "can create session with variables and relationships" do
      user = user()
      session = session()
      assert Ash.load!(session, :variables).variables == []
      var1 = variable(user: user, session: session)
      var2 = variable(user: user, session: session)
      assert Enum.count(Ash.load!(session, :variables).variables) == 2

      relationship = relationship(user: user, session: session, src: var1, dst: var2)

      session = Ash.load!(session, [:variables, :influence_relationships])

      assert session.variables |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([var1.id, var2.id])

      assert [rel] = session.influence_relationships
      assert rel.id == relationship.id

      var3 = variable(user: user, session: session)
      relationship2 = relationship(user: user, session: session, src: var1, dst: var3)

      session = Ash.load!(session, [:variables, :influence_relationships])

      assert length(session.variables) == 3
      assert length(session.influence_relationships) == 2

      assert MapSet.new(session.influence_relationships, & &1.id) ==
               MapSet.new([relationship.id, relationship2.id])
    end

    test "list endpoint orders by inserted_at descending" do
      first_session = session()
      Process.sleep(100)
      second_session = session()

      [latest, oldest] = Revelo.Sessions.list!()

      assert latest.id == second_session.id
      assert oldest.id == first_session.id
    end
  end
end
