defmodule Revelo.Diagrams do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Revelo.Diagrams.Variable do
      define :create_variable, args: [:name], action: :create
    end

    resource Revelo.Diagrams.Relationship do
      define :create_relationship, args: [:src, :dst], action: :create
    end

    resource Revelo.Diagrams.Loop
    resource Revelo.Diagrams.LoopRelationships

    # "vote" resources
    resource Revelo.Diagrams.VariableVote
    resource Revelo.Diagrams.RelationshipVote
    resource Revelo.Diagrams.LoopVote
  end
end
