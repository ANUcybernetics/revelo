defmodule ReveloWeb.BrowserTest do
  use PhoenixTest.Playwright.Case, async: true

  @moduletag :playwright
  @moduletag skip: "playwright tests"

  @tag trace: :open
  test "heading", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("h1", text: "Phoenix Framework")
  end
end
