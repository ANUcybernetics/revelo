defmodule Revelo.Diagrams.Relationship do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Variable
  alias Revelo.Sessions.Session

  calculations do
    calculate :reinforcing_votes,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.type = 'reinforcing')",
                  id
                )
              )

    calculate :balancing_votes,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM relationship_votes WHERE relationship_votes.relationship_id = ? AND relationship_votes.type = 'balancing')",
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
                  reinforcing_votes > 0 and balancing_votes > 0 -> :conflicting
                  reinforcing_votes > 0 and balancing_votes == 0 -> :reinforcing
                  balancing_votes > 0 and reinforcing_votes == 0 -> :balancing
                  true -> :no_relationship
                end
              ),
              load: [:reinforcing_votes, :balancing_votes]
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

      argument :include_hidden, :boolean do
        default false
      end

      filter expr(session.id == ^arg(:session_id) and (^arg(:include_hidden) or hidden? == false))

      prepare build(
                sort: [:src_id, :dst_id],
                load: [:reinforcing_votes, :balancing_votes, :no_relationship_votes, :type]
              )
    end

    read :list_actual do
      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(
               session.id == ^arg(:session_id) and
                 hidden? == false and
                 (balancing_votes > 0 or reinforcing_votes > 0)
             )

      prepare build(
                sort: [:src_id, :dst_id],
                load: [:reinforcing_votes, :balancing_votes, :no_relationship_votes, :type]
              )
    end

    create :create do
      accept [:description, :hidden?]

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

    update :hide do
      change set_attribute(:hidden?, true)
    end

    update :unhide do
      change set_attribute(:hidden?, false)
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
    attribute :hidden?, :boolean, allow_nil?: false, default: false

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
