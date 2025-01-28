defmodule Revelo.UserTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Ash.Error.Invalid
  alias Revelo.Accounts.User

  describe "test actions" do
    test "register_with_password creates a new user with valid attributes" do
      email = "test@example.com"
      password = "password123"
      password_confirmation = "password123"

      user =
        User
        |> Ash.Changeset.for_create(
          :register_with_password,
          %{
            email: email,
            password: password,
            password_confirmation: password_confirmation
          },
          authorize?: false
        )
        |> Ash.create!()

      assert Ash.CiString.value(user.email) == email
      assert user |> Ash.load!(:anonymous?) |> Map.get(:anonymous?) == false
    end

    test "register_with_password fails with invalid attributes" do
      email = "test@example.com"
      password = "short"
      password_confirmation = "short"

      assert_raise Invalid, fn ->
        User
        |> Ash.Changeset.for_create(
          :register_with_password,
          %{
            email: email,
            password: password,
            password_confirmation: password_confirmation
          },
          authorize?: false
        )
        |> Ash.create!()
      end
    end

    test "sign_in_with_password fails for invalid credentials" do
      email = "test@example.com"
      password = "password123"
      password_confirmation = "password123"

      User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{
          email: email,
          password: password,
          password_confirmation: password_confirmation
        },
        authorize?: false
      )
      |> Ash.create!()

      assert_raise Ash.Error.Forbidden, fn ->
        User
        |> Ash.Query.for_read(
          :sign_in_with_password,
          %{
            email: email,
            password: "wrongpassword"
          },
          authorize?: false
        )
        |> Ash.read!()
      end
    end

    test "register_anonymous_user creates a new user with auto-generated UUID" do
      user = Revelo.Accounts.register_anonymous_user!(authorize?: false)

      assert is_binary(user.id)
      assert String.length(user.id) == 36
      assert user.email == nil
      assert user.hashed_password == nil
      assert user |> Ash.load!(:anonymous?) |> Map.get(:anonymous?) == true
    end
  end

  describe "admin user actions" do
    test "can promote, demote and re-promote a user" do
      user =
        User
        |> Ash.Changeset.for_create(
          :register_with_password,
          %{
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          },
          authorize?: false
        )
        |> Ash.create!()

      assert user.admin == false

      admin_user =
        user
        |> Ash.Changeset.for_update(:promote_to_admin, %{}, authorize?: false)
        |> Ash.update!()

      assert admin_user.admin == true

      regular_user =
        admin_user
        |> Ash.Changeset.for_update(:demote_to_regular_user, %{}, authorize?: false)
        |> Ash.update!()

      assert regular_user.admin == false

      re_promoted_user =
        regular_user
        |> Ash.Changeset.for_update(:promote_to_admin, %{}, authorize?: false)
        |> Ash.update!()

      assert re_promoted_user.admin == true
    end
  end

  describe "calculated facilitator attribute" do
    test "facilitator calculation returns true when user is facilitator" do
      session = session()
      user = user()
      Revelo.Sessions.add_participant!(session, user)

      session
      |> Ash.Changeset.for_update(:add_participant, %{participant: user, facilitator: true}, authorize?: false)
      |> Ash.update!()

      user_with_calculation =
        Ash.load!(user, facilitator: [session_id: session.id])

      assert user_with_calculation.facilitator
    end

    test "facilitator calculation returns false when user is not facilitator" do
      session = session()
      user = user()
      Revelo.Sessions.add_participant!(session, user)

      session
      |> Ash.Changeset.for_update(:add_participant, %{participant: user, facilitator: false}, authorize?: false)
      |> Ash.update!()

      user_with_calculation =
        Ash.load!(user, facilitator: [session_id: session.id])

      refute user_with_calculation.facilitator
    end
  end
end
