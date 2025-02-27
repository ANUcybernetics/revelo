defmodule Revelo.LLMTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Revelo.LLM.Story

  describe "test real OpenAI API calls" do
    # @describetag skip: "requires OpenAI API key and costs money"

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
      # Create mock session struct with description
      session = %{
        description: "The hobbits in hobbiton are wondering what actions they should take."
      }

      # Create mock relationships
      relationships = [
        %{
          src: %{name: "Level of Sauron's Power"},
          dst: %{name: "Size of Orc Armies"},
          type: :direct
        },
        %{
          src: %{name: "Size of Orc Armies"},
          dst: %{name: "Sauron's Military Control over territories"},
          type: :direct
        },
        %{
          src: %{name: "Sauron's Military Control over territories"},
          dst: %{name: "Level of Sauron's Power"},
          type: :direct
        }
      ]

      # Create mock loop struct
      loop = %{
        type: :reinforcing,
        session: session,
        influence_relationships: relationships
      }

      {:ok, %Story{story: story, title: title}} = Revelo.LLM.generate_story(loop)

      assert story
      assert title
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

      loop =
        relationships
        |> Revelo.Diagrams.create_loop!(session, actor: user)
        |> Revelo.Diagrams.generate_loop_story!()

      assert loop.story
      assert loop.title
    end
  end
end
