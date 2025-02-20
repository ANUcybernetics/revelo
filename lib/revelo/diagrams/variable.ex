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

      prepare build(
                sort: [is_voi?: :desc, hidden?: :asc, vote_tally: :desc, name: :asc],
                load: [:voted?, :vote_tally]
              )
    end

    read :get_voi do
      get? true

      argument :session_id, :uuid do
        allow_nil? false
      end

      filter expr(session.id == ^arg(:session_id) and is_voi? == true)
    end

    create :create do
      accept [:is_voi?, :hidden?]
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
      change load :vote_tally
    end

    update :rename do
      argument :name, :string do
        allow_nil? false
      end

      change set_attribute(:name, arg(:name))
    end

    update :unset_voi do
      change set_attribute(:is_voi?, false)
    end

    update :toggle_voi do
      change fn changeset, _ ->
        current_value = Ash.Changeset.get_attribute(changeset, :is_voi?)
        Ash.Changeset.force_change_attribute(changeset, :is_voi?, !current_value)
      end

      # ensure there's only one variable of interest in any session
      change after_action(fn changeset, variable, _context ->
               if Ash.Changeset.get_attribute(changeset, :is_voi?) do
                 # Get the session ID from the variable
                 session_id = variable.session_id

                 # unset all other variables of interest in session
                 session_id
                 |> Revelo.Diagrams.list_variables!()
                 |> Enum.filter(fn v -> v.is_voi? && v.id != variable.id end)
                 |> Revelo.Diagrams.unset_voi!()
               end

               {:ok, Ash.load!(variable, :vote_tally)}
             end)
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

      change after_action(fn _changeset, variable, _context ->
               {:ok, Ash.load!(variable, :vote_tally)}
             end)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :is_voi?, :boolean, allow_nil?: false, default: false
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
