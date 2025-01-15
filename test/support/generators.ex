defmodule ReveloTest.Generators do
  @moduledoc false
  use Ash.Generator

  def session(opts \\ []) do
    changeset_generator(
      Revelo.Sessions.Session,
      :create,
      defaults: [
        name: sequence(:title, &"Session #{&1}"),
        description: StreamData.repeatedly(fn -> Faker.Lorem.paragraph() end)
      ],
      overrides: opts
    )
  end

  def user(opts \\ []) do
    seed_generator(
      %Revelo.Accounts.User{
        email: sequence(:unique_email, fn i -> "user#{i}@example.com" end),
        hashed_password: StreamData.string(:alphanumeric, min_length: 8)
      },
      overrides: opts
    )
  end

  # using `changeset_generator`, calls the action when passed to `generate`
  # def session_participant(opts \\ []) do
  #   session_id =
  #     opts[:session_id] || once(:default_session_id, fn -> generate(session()).id end)

  #   changeset_generator(
  #     Revelo.Accounts.User,
  #     :create,
  #     defaults: [
  #       session_id: session_id
  #     ],
  #     overrides: opts
  #   )
  # end
end
