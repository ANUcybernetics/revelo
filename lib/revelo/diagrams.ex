defmodule Revelo.Diagrams do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Revelo.Diagrams.Variable
    resource Revelo.Diagrams.Relationship
    resource Revelo.Diagrams.VariableVote
    resource Revelo.Diagrams.RelationshipVote
    resource Revelo.Diagrams.Loop
    resource Revelo.Diagrams.LoopRelationships
    resource Revelo.Diagrams.LoopVote
  end
end
