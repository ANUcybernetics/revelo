defmodule Revelo.Diagrams.Relationship do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshPostgres.DataLayer

  alias Revelo.Diagrams.Relationship
  alias Revelo.Diagrams.Variable
  alias Revelo.Sessions.Session

  postgres do
    table "relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :list_potential do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id) and not src.hidden? and not dst.hidden?)

      prepare build(
                sort: [:src_id, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :user_vote
                ]
              )
    end

    read :list_actual do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(
               session.id == ^arg(:session_id) and type != :no_relationship and
                 type != :conflicting
             )

      prepare build(
                sort: [:src_id, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :user_vote
                ]
              )
    end

    read :list_conflicting do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id) and direct_votes > 0 and inverse_votes > 0)

      prepare build(
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :user_vote
                ]
              )

      # sort by most controversial first
      after_action(fn _query, results, _context ->
        sorted_results =
          Enum.sort_by(results, fn record ->
            # Calculate the similarity between direct and inverse votes
            direct = record.direct_votes
            inverse = record.inverse_votes
            max_val = max(abs(direct), abs(inverse))

            similarity =
              if max_val == 0 do
                1.0
              else
                1.0 - abs(direct - inverse) / max_val
              end

            # Sort by most similar first (descending order of similarity)
            -similarity
          end)

        {:ok, sorted_results}
      end)
    end

    read :list_from_src do
      argument :src_id, :uuid do
        allow_nil? false
      end

      filter expr(src_id == ^arg(:src_id))

      prepare build(
                sort: [:user_vote, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :user_vote
                ]
              )
    end

    create :create do
      accept [:description]

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      argument :src, :struct do
        constraints instance_of: Variable
        allow_nil? false
      end

      argument :dst, :struct do
        constraints instance_of: Variable
        allow_nil? false
      end

      primary? true

      change manage_relationship(:session, type: :append)
      change manage_relationship(:src, type: :append)
      change manage_relationship(:dst, type: :append)
    end

    update :override_type do
      require_atomic? false

      argument :type, :atom do
        constraints one_of: [:inverse, :direct, :no_relationship]
        allow_nil? true
      end

      change set_attribute(:type_override, arg(:type))

      change after_action(fn _changeset, relationship, _context ->
               {:ok,
                Ash.load!(relationship, [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type
                ])}
             end)
    end

    action :enumerate, {:array, :struct} do
      constraints items: [instance_of: __MODULE__]

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      run fn input, _context ->
        session = input.arguments.session
        variables = Revelo.Diagrams.list_variables!(session.id)

        relationships =
          for src <- variables,
              dst <- variables,
              src.id != dst.id do
            case Ash.get(Relationship, src_id: src.id, dst_id: dst.id) do
              {:ok, existing} ->
                existing

              {:error, _} ->
                Revelo.Diagrams.create_relationship!(src, dst, session)
            end
          end

        {:ok, relationships}
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :description, :string
    attribute :type_override, :atom

    timestamps()
  end

  relationships do
    belongs_to :session, Session do
      allow_nil? false
    end

    belongs_to :src, Variable do
      allow_nil? false
    end

    belongs_to :dst, Variable do
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.RelationshipVote do
      destination_attribute :relationship_id
    end

    many_to_many :loops, Revelo.Diagrams.Loop do
      through Revelo.Diagrams.LoopRelationships
      source_attribute_on_join_resource :relationship_id
      destination_attribute_on_join_resource :loop_id
    end
  end

  calculations do
    calculate :direct_votes,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.type = 'direct')",
                  id
                )
              )

    calculate :inverse_votes,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.type = 'inverse')",
                  id
                )
              )

    calculate :no_relationship_votes,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.type = 'no_relationship')",
                  id
                )
              )

    calculate :type,
              :atom,
              expr(
                cond do
                  not is_nil(type_override) ->
                    type_override

                  direct_votes > 0 and inverse_votes > 0 ->
                    :conflicting

                  direct_votes > 0 and direct_votes >= no_relationship_votes and
                      inverse_votes == 0 ->
                    :direct

                  inverse_votes > 0 and inverse_votes >= no_relationship_votes and
                      direct_votes == 0 ->
                    :inverse

                  true ->
                    :no_relationship
                end
              ),
              load: [:direct_votes, :inverse_votes]

    calculate :conflictedness,
              :float,
              expr(
                fragment(
                  """
                  CASE
                    WHEN (? + ? + ?) = 0 THEN 0.0
                    ELSE (
                      WITH total_votes AS (
                        SELECT ? + ? + ? AS total
                      ),
                      probabilities AS (
                        SELECT
                          (? * 1.0 / total) AS p_direct,
                          (? * 1.0 / total) AS p_inverse,
                          (? * 1.0 / total) AS p_none
                        FROM total_votes
                      ),
                      entropy_terms AS (
                        SELECT
                          CASE WHEN p_direct > 0 THEN -p_direct * LOG(p_direct) / LOG(2) ELSE 0 END +
                          CASE WHEN p_inverse > 0 THEN -p_inverse * LOG(p_inverse) / LOG(2) ELSE 0 END +
                          CASE WHEN p_none > 0 THEN -p_none * LOG(p_none) / LOG(2) ELSE 0 END AS entropy
                        FROM probabilities
                      )
                      SELECT entropy / 1.585 FROM entropy_terms
                    )
                  END
                  """,
                  direct_votes,
                  inverse_votes,
                  no_relationship_votes,
                  direct_votes,
                  inverse_votes,
                  no_relationship_votes,
                  direct_votes,
                  inverse_votes,
                  no_relationship_votes
                )
              ),
              load: [:direct_votes, :inverse_votes, :no_relationship_votes]

    calculate :user_vote,
              :string,
              expr(
                fragment(
                  "(SELECT type FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.voter_id = ?::uuid LIMIT 1)",
                  id,
                  type(^actor(:id), :binary_id)
                )
              )
  end

  identities do
    identity :unique_relationship, [:src_id, :dst_id]
  end
end
