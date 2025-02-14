defmodule Revelo.Diagrams.Relationship do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Variable
  alias Revelo.Sessions.Session

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

                  direct_votes > 0 and inverse_votes == 0 ->
                    :direct

                  inverse_votes > 0 and direct_votes == 0 ->
                    :inverse

                  true ->
                    :no_relationship
                end
              ),
              load: [:direct_votes, :inverse_votes]

    calculate :voted?, :boolean, expr(exists(votes, voter_id == ^actor(:id)))
  end

  sqlite do
    table "relationships"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :list_potential do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id))

      prepare build(
                sort: [:src_id, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :voted?
                ]
              )
    end

    read :list_actual do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id) and type != :no_relationship)

      prepare build(
                sort: [:src_id, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :voted?
                ]
              )
    end

    read :list_conflicting do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id) and direct_votes > 0 and inverse_votes > 0)

      prepare build(
                sort: [:src_id, :dst_id],
                load: [
                  :src,
                  :dst,
                  :direct_votes,
                  :inverse_votes,
                  :no_relationship_votes,
                  :type,
                  :voted?
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
            case Ash.get(Revelo.Diagrams.Relationship, src_id: src.id, dst_id: dst.id) do
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
  end

  identities do
    identity :unique_relationship, [:src_id, :dst_id]
  end
end
