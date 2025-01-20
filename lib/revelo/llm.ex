defmodule Revelo.LLM.UserInfo do
  @moduledoc false
  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:age, :integer)
  end
end

defmodule Revelo.LLM do
  @moduledoc false

  def generate_variables(key_variable, count) do
    InstructorLite.instruct(
      %{
        messages: [
          %{role: "user", content: "John Doe is fourty two years old"}
        ]
      },
      response_model: Revelo.LLM.UserInfo,
      adapter_context: [api_key: Application.fetch_env!(:instructor_lite, :openai_api_key)]
    )
  end
end
