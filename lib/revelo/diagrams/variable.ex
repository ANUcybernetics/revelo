defmodule Revelo.Diagrams.Variable do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Accounts.User
  alias Revelo.Sessions.Session

  calculations do
    # TODO this seems to be required because ash_sqlite doesn't support count
    # aggregates in expressions (or in aggregates)
    calculate :vote_tally,
              :integer,
              expr(
                fragment(
                  "(SELECT COUNT(*) FROM variable_votes WHERE variable_votes.variable_id = ?)",
                  id
                )
              )

    calculate :voted?, :boolean, expr(exists(votes, voter_id == ^actor(:id)))
  end

  sqlite do
    table "variables"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      argument :session_id, :uuid do
        allow_nil? false
      end

      argument :include_hidden, :boolean do
        default false
      end

      filter expr(session.id == ^arg(:session_id) and (^arg(:include_hidden) or hidden? == false))
      prepare build(sort: [is_key?: :desc, name: :asc], load: :voted?)
    end

    create :create do
      accept [:is_key?, :hidden?]
      primary? true

      argument :name, :string do
        allow_nil? false
      end

      argument :session, :struct do
        constraints instance_of: Session
        allow_nil? false
      end

      change relate_actor(:creator)
      change manage_relationship(:session, type: :append)
      change set_attribute(:name, arg(:name))
    end

    update :rename do
      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))
    end

    update :set_key do
      change set_attribute(:is_key?, true)
    end

    update :unset_key do
      change set_attribute(:is_key?, false)
    end

    update :toggle_key do
      change fn changeset, _ ->
        current_value = Ash.Changeset.get_attribute(changeset, :is_key?)
        Ash.Changeset.force_change_attribute(changeset, :is_key?, !current_value)
      end
    end

    update :hide do
      change set_attribute(:hidden?, true)
    end

    update :unhide do
      change set_attribute(:hidden?, false)
    end

    update :toggle_visibility do
      change fn changeset, _ ->
        current_value = Ash.Changeset.get_attribute(changeset, :hidden?)
        Ash.Changeset.force_change_attribute(changeset, :hidden?, !current_value)
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :is_key?, :boolean, allow_nil?: false, default: false
    attribute :hidden?, :boolean, allow_nil?: false, default: false

    timestamps()
  end

  relationships do
    belongs_to :session, Session do
      allow_nil? false
    end

    belongs_to :creator, User do
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.VariableVote do
      destination_attribute :variable_id
    end
  end

  identities do
    identity :unique_name, [:name, :session_id]
  end
end
