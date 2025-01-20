defmodule Revelo.LLMTest do
  use Revelo.DataCase

  alias Revelo.LLM

  describe "test real OpenAI API calls" do
    @describetag skip: "requires OpenAI API key and costs money"

    test "LLM.generate_variables returns sensible response" do
      {:ok, user_info} = Revelo.LLM.generate_variables("Sauron", 5)
      assert user_info
    end
  end
end
