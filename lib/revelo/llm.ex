defmodule Revelo.LLM.VariableList do
  @moduledoc false
  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field(:variables, {:array, :string})
  end
end

defmodule Revelo.LLM.Story do
  @moduledoc false
  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field(:story, :string)
    field(:title, :string)
  end
end

defmodule Revelo.LLM.Title do
  @moduledoc false
  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field(:title, :string)
  end
end

defmodule Revelo.LLM do
  @moduledoc false

  alias Revelo.LLM.Story
  alias Revelo.LLM.VariableList

  def generate_variables(description, count, variables) do
    ensure_api_key_present!()

    if count == "0" do
      {:ok, %VariableList{variables: []}}
    else
      InstructorLite.instruct(
        %{
          messages: [
            %{
              role: "system",
              content: ~S"""
              You are a systems engineer that generates JSON-formatted variable names for system diagrams, following these rules:

              1. Use nouns or noun phrases to name variables.
              2. Ensure that the name given to a variable makes it clear that the thing or characteristic referred to is capable of change.
              3. Avoid using surrogate variables (such as, for example, Level of trust in the community) unless it is necessary.
              4. Use the same rules for naming intangible variables, such as Happiness, as you would for tangible variables.
              5. Avoid using variable names that refer to things that are not usually reported using numbers, such as Population, Cost, or Distance.
              6. Check that the name of the variable can be thought about in terms of quantity, i.e., it works in the sentence "As [variable] increases"

              You will be a description of the system that should decide most of your variables.

              You will also be provided with a number N, and you will generate N different variable names that follow all the rules above.

              Finally, you will be provided with a list of existing variables. Try to generate variables that are unlike the exisiting ones.
              """
            },
            %{
              role: "user",
              content: "System Description: #{description}, N: #{count}, Existing variables: #{variables}"
            }
          ],
          model: "gpt-4o-mini"
        },
        response_model: VariableList,
        adapter_context: [api_key: Application.fetch_env!(:instructor_lite, :openai_api_key)]
      )
    end
  end

  def generate_story(loop) do
    ensure_api_key_present!()

    # Process the loop data
    relationship_string = process_relationship_string(loop.influence_relationships)
    session_description = loop.session.description
    loop_type = Atom.to_string(loop.type)

    InstructorLite.instruct(
      %{
        messages: [
          %{
            role: "system",
            content: ~S"""
            You are a systems engineer skilled at crafting engaging, concise, and imaginative 1-2 sentence stories that illustrate the dynamics of feedback loops.
            Using the relationships between the items in the system, explain how the loop is stablizes itself (balancing) or doesn't (reinforcing).
            Ensure the story highlights the system's state as it evolves, staying true to the actual dynamics. Avoid making value judgements about whether
            the behaviour is desirable or undesirable. Try to be concise, but still logical!

            The context provided is for reference only and should not influence the content of the loop.

            You must start the story with the first variable of the provided loop.

            Make your title inspired by the story you create – it should not mention a loop or cycle in the title, but rather condense the dynamics into 3-8 words.
            """
          },
          %{
            role: "user",
            content: "Context: #{session_description}, loop: #{relationship_string}, feedback type: #{loop_type}"
          }
        ],
        model: "gpt-4o"
      },
      response_model: Story,
      adapter_context: [
        api_key: Application.fetch_env!(:instructor_lite, :openai_api_key)
      ]
    )
  end

  # Helper function to process relationships into a string
  defp process_relationship_string(relationships) do
    relationships
    |> Enum.reduce({"", []}, fn rel, {prev_connector, acc} ->
      connector =
        case {prev_connector, rel.type} do
          {"", :inverse} -> :decrease
          {"", :direct} -> :increase
          {:decrease, :inverse} -> :increase
          {:decrease, :direct} -> :decrease
          {:increase, :inverse} -> :decrease
          {:increase, :direct} -> :increase
        end

      cur_text =
        case {prev_connector, connector} do
          {"", :decrease} ->
            "Increasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

          {"", :increase} ->
            "Increasing #{rel.src.name} directly causes #{rel.dst.name} to increase"

          {:decrease, :increase} ->
            "Decreasing #{rel.src.name} directly causes #{rel.dst.name} to increase"

          {:decrease, :decrease} ->
            "Decreasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

          {:increase, :decrease} ->
            "Increasing #{rel.src.name} directly causes #{rel.dst.name} to decrease"

          {:increase, :increase} ->
            "Increasing #{rel.src.name} directly causes #{rel.dst.name} to increase"
        end

      {connector, acc ++ [cur_text]}
    end)
    |> elem(1)
    |> Enum.join("; ")
  end

  defp ensure_api_key_present! do
    case Application.fetch_env!(:instructor_lite, :openai_api_key) do
      nil ->
        raise "OpenAI API key is required but not configured. Set the OPENAI_API_KEY environment variable."

      _ ->
        :ok
    end
  end
end
