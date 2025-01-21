defmodule Revelo.LLMTest do
  use Revelo.DataCase

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

    test "LLM.generate_story returns sensible response" do
      {:ok, story} =
        Revelo.LLM.generate_story(
          "The hobbits in hobbiton are wondering what actions they should take.",
          "Level of Sauron's power",
          "[Level of Sauron's Power increases Size of Orc Armies increases Sauron's Military Control over territories increases Level of Sauron's Power]",
          "Reinforcing"
        )

      assert story
    end
  end
end
