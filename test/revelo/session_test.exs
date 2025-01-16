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

    test "can create session with participant" do
      user = generate(user())
      user2 = generate(user())
      session = generate(session())

      Ash.get!(User, user.id, authorize?: false)

      session =
        session
        |> Ash.Changeset.for_update(:add_participants, %{participants: [user]})
        |> Ash.update!()

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 1

      assert session.participants == [user]

      # add a second user
      session =
        session
        |> Ash.Changeset.for_update(:add_participants, %{participants: [user2]})
        |> Ash.update!()
        |> Ash.load!(:participants, authorize?: false)

      assert SessionParticipants |> Ash.read!() |> Enum.count() == 2
      assert length(session.participants) == 2
      assert Enum.map(session.participants, & &1.id) == [user.id, user2.id]
    end
  end

  # describe "relationships" do
  #   test "can add participants to session" do
  #     {:ok, session} = Ash.create(Session, %{name: "Test Session"})
  #     {:ok, user} = Ash.create(Revelo.Accounts.User, %{name: "Test User", email: "test@test.com"})

  #     {:ok, _} = Ash.update(session, include_participants: [user])

  #     updated_session = Ash.load!(session, :participants)
  #     assert length(updated_session.participants) == 1
  #   end
  # end
end
