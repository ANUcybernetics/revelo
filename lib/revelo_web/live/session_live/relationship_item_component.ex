defmodule ReveloWeb.SessionLive.RelationshipItemComponent do
  @moduledoc """
  Component for displaying a single relationship in the relationship table.
  """
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents

  alias Revelo.Diagrams

  @impl true
    def render(assigns) do
      ~H"""
      <div class="flex items-center gap-2 items-start">
        <span class="flex-[1_1_25%] text-right">{@relationship.src.name}</span>
        <.icon name="hero-minus" class="h-4 w-4" />
        <div class="flex items-center gap-1">
          <.tooltip>
            <tooltip_trigger>
              <button
                phx-click="relationship_toggle_override"
                phx-value-src_id={@relationship.src_id}
                phx-value-dst_id={@relationship.dst_id}
                phx-value-relationship_id={@relationship.id}
                phx-value-type="direct"
                class={[
                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors ",
                  cond do
                    @relationship.type_override == :direct ||
                        (@relationship.type_override == nil &&
                           @relationship.type == :direct) ->
                      "bg-direct text-direct-foreground border-[length:var(--border-thickness)] !border-direct-foreground/50"

                    true ->
                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                  end
                ]}
              >
                <div class="relative h-4 w-4 flex items-center justify-center">
                  <div
                    class="h-4 w-4 transition-all"
                    style="mask: url('/images/direct.svg') no-repeat; -webkit-mask: url('/images/direct.svg') no-repeat; background-color: currentColor;"
                  />
                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-direct-light text-direct-foreground text-[0.6rem] flex items-center justify-center h-3 w-3">
                    {@relationship.direct_votes}
                  </div>
                </div>
                <span class="sr-only">
                  Direct Votes
                </span>
              </button>
            </tooltip_trigger>
            <.tooltip_content side="top">
              Direct Votes
            </.tooltip_content>
          </.tooltip>
          <.tooltip>
            <tooltip_trigger>
              <button
                phx-click="relationship_toggle_override"
                phx-value-src_id={@relationship.src_id}
                phx-value-dst_id={@relationship.dst_id}
                phx-value-relationship_id={@relationship.id}
                phx-value-type="no_relationship"
                class={[
                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors ",
                  cond do
                    @relationship.type_override == :no_relationship ||
                        (@relationship.type_override == nil &&
                           @relationship.type == :no_relationship) ->
                      "bg-gray-300 text-gray-700 border-[length:var(--border-thickness)] !border-gray-700/50"

                    true ->
                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                  end
                ]}
              >
                <div class="relative h-4 w-4 flex items-center justify-center">
                  <.icon name="hero-no-symbol" class="h-4 w-4" />
                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-gray-300 text-gray-700 text-[0.6rem] flex items-center justify-center h-3 w-3">
                    {@relationship.no_relationship_votes}
                  </div>
                </div>
                <span class="sr-only">
                  No Relationship Votes
                </span>
              </button>
            </tooltip_trigger>
            <.tooltip_content side="top">
              No Relationship Votes
            </.tooltip_content>
          </.tooltip>
          <.tooltip>
            <tooltip_trigger>
              <button
                phx-click="relationship_toggle_override"
                phx-value-src_id={@relationship.src_id}
                phx-value-dst_id={@relationship.dst_id}
                phx-value-relationship_id={@relationship.id}
                phx-value-type="inverse"
                class={[
                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors",
                  cond do
                    @relationship.type_override == :inverse ||
                        (@relationship.type_override == nil &&
                           @relationship.type == :inverse) ->
                      "bg-inverse text-inverse-foreground border-[length:var(--border-thickness)] !border-inverse-foreground/50"

                    true ->
                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                  end
                ]}
              >
                <div class="relative h-4 w-4 flex items-center justify-center">
                  <.icon name="hero-arrows-up-down" class="h-4 w-4" />
                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-inverse-light text-inverse-foreground text-[0.6rem] flex items-center justify-center h-3 w-3">
                    {@relationship.inverse_votes}
                  </div>
                </div>
                <span class="sr-only">
                  Inverse Votes
                </span>
              </button>
            </tooltip_trigger>
            <.tooltip_content side="top">
              Inverse Votes
            </.tooltip_content>
          </.tooltip>
        </div>
        <.icon name="hero-arrow-long-right" class="h-4 w-4" />
        <span class="flex-[1_1_25%]">{@relationship.dst.name}</span>
      </div>
      """
    end
end
