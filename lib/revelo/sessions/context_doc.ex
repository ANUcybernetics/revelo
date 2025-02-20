defmodule Revelo.Sessions.ContextDoc do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Sessions,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "context_docs"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :text, :string do
      allow_nil? false
    end

    attribute :include?, :boolean do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :session, Revelo.Sessions.Session do
      allow_nil? false
    end
  end
end
