defmodule Revelo.Diagrams do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Revelo.Diagrams.Variable do
      define :create_variable, args: [:name, :session], action: :create
      define :list_variables, args: [:session_id], action: :list
      define :set_key_variable, action: :set_key
      define :unset_key_variable, action: :unset_key
      define :hide_variable, action: :hide
      define :unhide_variable, action: :unhide
    end

    resource Revelo.Diagrams.Relationship do
      define :create_relationship, args: [:src, :dst, :session], action: :create
    end

    resource Revelo.Diagrams.Loop
    resource Revelo.Diagrams.LoopRelationships

    # "vote" resources
    resource Revelo.Diagrams.VariableVote
    resource Revelo.Diagrams.RelationshipVote
  end
end
