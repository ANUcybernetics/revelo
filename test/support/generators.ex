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

  def variable(opts \\ []) do
    user = opts[:user] || generate(user())
    session = opts[:session] || generate(session())

    changeset_generator(Revelo.Diagrams.Variable, :create,
      defaults: %{
        name: sequence(:title, &"Variable #{&1}"),
        description: sequence(:description, &"Description #{&1}"),
        session_id: session.id
      },
      overrides: opts,
      actor: user
    )
  end
end
