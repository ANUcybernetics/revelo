defmodule Revelo.SessionTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Sessions.Session

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

      session =
        session
        |> Ash.Changeset.for_update(:add_participants, %{participants: [user]})
        |> Ash.update!()

      assert session.participants == [user]

      # add a second user
      session =
        session
        |> Ash.Changeset.for_update(:add_participants, %{participants: [user2]})
        |> Ash.update!()

      assert session.participants == [user, user2]
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
