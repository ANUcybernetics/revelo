defmodule Revelo.LoopTest do
  use Revelo.DataCase

  import ExUnitProperties
  import ReveloTest.Generators

  alias Revelo.Diagrams.Loop
  alias Revelo.Diagrams.Relationship
  alias Revelo.Diagrams.Variable

  describe "loop actions" do
    @describetag skip: "currently not working"
    test "can create loop" do
      loop = loop()

      assert loop
      assert is_list(loop.influence_relationships)
    end

    test "can add variables to loop" do
    end
  end
end
