defmodule ReveloTest.Generators do
  @moduledoc false
  use Ash.Generator

  alias Revelo.Diagrams.Variable

  def session do
    input =
      %{
        name: sequence(:title, &"Session #{&1}"),
        description: StreamData.repeatedly(fn -> Faker.Lorem.paragraph() end)
      }
      |> StreamData.fixed_map()
      |> ExUnitProperties.pick()

    Revelo.Sessions.Session |> Ash.Changeset.for_create(:create, input) |> Ash.create!()
  end

  def user do
    %Revelo.Accounts.User{
      email: sequence(:unique_email, fn i -> "user#{i}@example.com" end),
      hashed_password: StreamData.string(:alphanumeric, min_length: 8)
    }
    |> seed_generator()
    |> generate()
  end

  def variable(opts \\ []) do
    {user, opts} = Keyword.pop_lazy(opts, :user, fn -> user() end)
    {session, opts} = Keyword.pop_lazy(opts, :session, fn -> session() end)

    input =
      %{
        name: sequence(:variable_name, &"Variable #{&1}"),
        description: StreamData.repeatedly(fn -> Faker.Lorem.paragraph() end),
        session: StreamData.constant(session)
      }
      |> StreamData.fixed_map()
      |> ExUnitProperties.pick()
      |> Map.merge(Map.new(opts))

    Variable |> Ash.Changeset.for_create(:create, input, actor: user) |> Ash.create!()
  end

  def relationship(opts \\ []) do
    {user, opts} = Keyword.pop_lazy(opts, :user, fn -> user() end)
    {session, opts} = Keyword.pop_lazy(opts, :session, fn -> session() end)
    {src, opts} = Keyword.pop_lazy(opts, :src, fn -> variable(session: session, user: user) end)
    {dst, opts} = Keyword.pop_lazy(opts, :dst, fn -> variable(session: session, user: user) end)

    input =
      %{
        session: StreamData.constant(session),
        src: StreamData.constant(src),
        dst: StreamData.constant(dst)
      }
      |> StreamData.fixed_map()
      |> ExUnitProperties.pick()
      |> Map.merge(Map.new(opts))

    Revelo.Diagrams.Relationship
    |> Ash.Changeset.for_create(:create, input, actor: user)
    |> Ash.create!()
  end
end
