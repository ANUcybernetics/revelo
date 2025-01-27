# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Revelo.Repo.insert!(%Revelo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Revelo.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "ben@benswift.me",
  password: "cyber123",
  password_confirmation: "cyber123"
})
|> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
|> Ash.create!(authorize?: false)
|> Ash.Changeset.for_update(:promote_to_admin, %{})
|> Ash.update!(authorize?: false)
