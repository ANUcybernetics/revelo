defmodule Revelo.LLMTest do
  use Revelo.DataCase

  alias Revelo.LLM

  describe "test real OpenAI API calls" do
    @describetag skip: "requires OpenAI API key and costs money"

    test "LLM.generate_variables returns sensible response" do
      {:ok, variable_list} =
        Revelo.LLM.generate_variables(
          "The hobbits in hobbiton are wondering what actions they should take.",
          "Level of Sauron's power",
          5
        )

      assert variable_list
    end
  end
end
