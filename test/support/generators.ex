defmodule ReveloTest.Generators do
  @moduledoc false
  use Ash.Generator

  alias Revelo.Accounts.User
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
    %User{
      email: sequence(:unique_email, fn i -> "user#{i}@example.com" end),
      hashed_password: StreamData.string(:alphanumeric, min_length: 8)
    }
    |> seed_generator()
    |> generate()
  end

  def user_with_password(password) do
    input = %{
      email: :unique_email |> sequence(fn i -> "user#{i}@example.com" end) |> ExUnitProperties.pick(),
      password: password,
      password_confirmation: password
    }

    User
    |> Ash.Changeset.for_create(:register_with_password, input)
    |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
    |> Ash.create!(authorize?: false)
  end

  def variable(opts \\ []) do
    {user, opts} = Keyword.pop_lazy(opts, :user, fn -> user() end)
    {session, opts} = Keyword.pop_lazy(opts, :session, fn -> session() end)

    input =
      %{
        name: sequence(:variable_name, &"Variable #{&1}"),
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

  def loop do
    # a simple loop of length 3 (in future we might make this generator more sophisticated)
    user = user()
    session = session()
    variables = Enum.map(1..3, fn _ -> variable(session: session, user: user) end)

    relationships =
      variables
      # add the first variable to the end to "close" the loop
      |> List.insert_at(-1, List.first(variables))
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [src, dst] ->
        relationship(src: src, dst: dst, session: session, user: user)
      end)

    input =
      %{
        relationships: StreamData.constant(relationships),
        story: StreamData.repeatedly(fn -> Faker.Lorem.paragraph() end),
        display_order: StreamData.positive_integer()
      }
      |> StreamData.fixed_map()
      |> ExUnitProperties.pick()

    Revelo.Diagrams.Loop
    |> Ash.Changeset.for_create(:create, input, actor: user)
    |> Ash.create!()
  end
end
