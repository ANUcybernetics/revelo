defmodule Revelo.UserTest do
  use Revelo.DataCase

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

    test "register_anonymous_user creates a new user with only a UUID" do
      uuid = Ecto.UUID.generate()

      user =
        User
        |> Ash.Changeset.for_create(
          :register_anonymous_user,
          %{
            id: uuid
          },
          authorize?: false
        )
        |> Ash.create!()

      assert user.id == uuid
      assert user.email == nil
      assert user.hashed_password == nil
    end
  end
end
