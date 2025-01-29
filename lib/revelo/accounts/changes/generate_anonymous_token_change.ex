defmodule Revelo.Accounts.Changes.GenerateAnonymousTokenChange do
  @moduledoc false
  use Ash.Resource.Change

  alias AshAuthentication.Jwt

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, result ->
      case Jwt.token_for_user(result, %{"purpose" => "anonymous"}) do
        {:ok, token, _claims} ->
          {:ok, Ash.Resource.put_metadata(result, :token, token)}

        _ ->
          {:ok, result}
      end
    end)
  end
end
