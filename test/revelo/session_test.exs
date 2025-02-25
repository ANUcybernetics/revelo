defmodule Revelo.SessionTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Revelo.Sessions.SessionParticipants

  describe "session actions" do
    test "overrides passed through to generator work properly" do
      user = user()
      session = session(user)
      variable = variable(user: user, session: session)
      assert variable.creator == user
      assert variable.session == session
    end

    test "can create session and add a participant" do
      creator = user()
      session = session(creator)

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 1

      assert session.participants == [creator]

      # add a participant
      participant = user()
      session = Revelo.Sessions.add_participant!(session, participant)
      session = Ash.load!(session, :participants, authorize?: false)

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 2
      assert length(session.participants) == 2

      assert MapSet.new(Enum.map(session.participants, & &1.id)) ==
               MapSet.new([creator.id, participant.id])
    end

    test "add_participant! works with facilitator option" do
      creator = user()
      session = session(creator)

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 1

      assert session.participants == [creator]

      # add a participant
      participant = user()
      session = Revelo.Sessions.add_participant!(session, participant, true)
      session = Ash.load!(session, :participants, authorize?: false)

      session_participant =
        Ash.get!(SessionParticipants,
          session_id: session.id,
          participant_id: participant.id
        )

      assert session_participant.facilitator? == true
      assert length(session.participants) == 2
      assert session.participants |> MapSet.new(& &1.id) |> MapSet.member?(creator.id)
    end

    test "can create session with variables and relationships" do
      user = user()
      session = session(user)
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
      user = user()
      first_session = session(user)
      Process.sleep(100)
      second_session = session(user)

      [latest, oldest] = Revelo.Sessions.list!()

      assert latest.id == second_session.id
      assert oldest.id == first_session.id
    end
  end
end
