defmodule Revelo.Diagrams do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Revelo.Diagrams.Variable do
      define :create_variable, args: [:name, :session], action: :create
      define :destroy_variable, action: :destroy
      define :list_variables, args: [:session_id, {:optional, :include_hidden}], action: :list
      define :unset_key_variable, action: :unset_key
      define :toggle_key_variable, action: :toggle_key
      define :hide_variable, action: :hide
      define :unhide_variable, action: :unhide
      define :toggle_variable_visibility, action: :toggle_visibility
    end

    resource Revelo.Diagrams.Relationship do
      define :create_relationship, args: [:src, :dst, :session], action: :create

      define :list_potential_relationships,
        args: [:session_id, {:optional, :include_hidden}],
        action: :list_potential

      define :list_actual_relationships, args: [:session_id], action: :list_actual

      define :enumerate_relationships, args: [:session], action: :enumerate
      define :hide_relationship, action: :hide
      define :unhide_relationship, action: :unhide
    end

    resource Revelo.Diagrams.Loop do
      define :scan_session, args: [:session_id]
      define :create_loop, args: [:relationships], action: :create
    end

    resource Revelo.Diagrams.LoopRelationships

    # "vote" resources
    resource Revelo.Diagrams.VariableVote do
      define :variable_vote, args: [:variable], action: :create
      define :destroy_variable_vote, action: :destroy
      define :list_variable_votes, args: [:session_id], action: :list
    end

    resource Revelo.Diagrams.RelationshipVote do
      define :relationship_vote, args: [:relationship, :type], action: :create
      define :list_relationship_votes, args: [:session_id], action: :list
    end
  end
end
