defmodule Revelo.LLM.VariableList do
  @moduledoc false
  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field(:variables, {:array, :string})
  end
end

defmodule Revelo.LLM do
  @moduledoc false

  def generate_variables(description, key_variable, count) do
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

            A key variable will also be provided, which we are interested to track the influence of.

            You will also be provided with a number N, and you will generate N different variable names that follow all the rules above.
            """
          },
          %{
            role: "user",
            content: "System Description: #{description}, Key Variable: #{key_variable}, N: #{count}"
          }
        ]
      },
      response_model: Revelo.LLM.VariableList,
      adapter_context: [api_key: Application.fetch_env!(:instructor_lite, :openai_api_key)]
    )
  end
end
