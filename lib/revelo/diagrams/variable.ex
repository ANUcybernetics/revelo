defmodule Revelo.Diagrams.Variable do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "variables"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :description, :string do
      allow_nil? false
    end

    attribute :voi?, :boolean do
      allow_nil? false
    end

    attribute :included?, :boolean do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :session, Revelo.Sessions.Session do
      attribute_type :uuid_v7
      allow_nil? false
    end

    belongs_to :creator, Revelo.Accounts.User do
      attribute_type :uuid_v7
      allow_nil? false
    end

    has_many :votes, Revelo.Diagrams.VariableVote
  end
end
