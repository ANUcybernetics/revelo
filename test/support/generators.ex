defmodule ReveloTest.Generators do
  @moduledoc false
  use Ash.Generator

  alias Revelo.Diagrams.Variable

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
    # note there may be a better way to use opts here, rather than having it do
    # double duty as "pass through user and session" and "pass through overrides"
    user = opts[:user] || generate(user())
    session = opts[:session] || generate(session())

    changeset_generator(Variable, :create,
      defaults: %{
        name: sequence(:title, &"Variable #{&1}"),
        session_id: session.id
      },
      overrides: opts,
      actor: user
    )
  end

  def relationship(opts \\ []) do
    user = opts[:user] || generate(user())
    session = opts[:session] || generate(session(user: user))
    src = opts[:src] || generate(variable(session: session, user: user))
    dst = opts[:dst] || generate(variable(session: session, user: user))

    changeset_generator(Revelo.Diagrams.Relationship, :create,
      defaults: %{
        session_id: session.id,
        src_id: src.id,
        dst_id: dst.id
      },
      overrides: opts,
      actor: user
    )
  end
end
