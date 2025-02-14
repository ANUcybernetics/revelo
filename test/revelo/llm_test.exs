defmodule Revelo.LLMTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  describe "test real OpenAI API calls" do
    @describetag skip: "requires OpenAI API key and costs money"

    test "LLM.generate_variables returns sensible response" do
      {:ok, variable_list} =
        Revelo.LLM.generate_variables(
          "The hobbits in hobbiton are wondering what actions they should take.",
          "Level of Sauron's power",
          5,
          ["Number of orcs"]
        )

      assert variable_list
    end

    test "LLM.generate_story returns sensible response" do
      {:ok, story} =
        Revelo.LLM.generate_story(
          "The hobbits in hobbiton are wondering what actions they should take.",
          "[Level of Sauron's Power increases Size of Orc Armies increases Sauron's Military Control over territories increases Level of Sauron's Power]",
          "Reinforcing"
        )

      assert story
    end

    test "generate_loop_story calls generate_story with correct arguments" do
      user = user()
      session = session(user)

      # Create variables for the loop
      var_a = variable(session: session, user: user)
      var_b = variable(session: session, user: user)

      # Create simple a->b->a loop
      relationships = [
        relationship_with_vote(
          src: var_a,
          dst: var_b,
          session: session,
          user: user,
          vote_type: :direct
        ),
        relationship_with_vote(
          src: var_b,
          dst: var_a,
          session: session,
          user: user,
          vote_type: :direct
        )
      ]

      loop = Revelo.Diagrams.create_loop!(relationships, actor: user)

      story = Revelo.Diagrams.generate_loop_story!(loop, actor: user)

      assert story
    end

    test "LLM.generate_title returns sensible response" do
      {:ok, title} =
        Revelo.LLM.generate_title(
          "The hobbits in hobbiton are wondering what actions they should take.",
          "[Level of Sauron's Power increases Size of Orc Armies increases Sauron's Military Control over territories increases Level of Sauron's Power]",
          "Reinforcing"
        )

      assert title
    end
  end
end
