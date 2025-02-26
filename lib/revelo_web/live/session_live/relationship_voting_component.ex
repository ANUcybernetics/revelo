defmodule ReveloWeb.SessionLive.RelationshipVotingComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  import ReveloWeb.Component.Card

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    relationships =
      assigns.session.id
      |> Diagrams.list_potential_relationships!(actor: assigns.current_user)
      |> Enum.group_by(& &1.src.name)
      |> Map.values()
      |> then(fn relationships ->
        rotation = :erlang.phash2(assigns.current_user.id, length(relationships))

        case rotation do
          0 -> relationships
          n -> Enum.slice(relationships, n..-1//1) ++ Enum.slice(relationships, 0..(n - 1))
        end
      end)

    # Get the count of votes made by the current user
    vote_count =
      relationships
      |> List.flatten()
      |> Enum.count(&(&1.voted? != nil))

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:relationships, fn -> relationships end)
      |> assign_new(:current_page, fn -> 1 end)
      |> assign(:total_pages, length(relationships))
      |> assign(:vote_count, vote_count)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl w-md min-w-[80svw] h-full p-5 pb-2 flex flex-col">
      <.card class="overflow-hidden grow flex flex-col">
        <.card_header class="border-b-[1px] border-gray-300 pb-2 mx-2 px-4">
          <.card_title class="font-normal leading-2 text-xl">
            Increasing the <br />
            <b>
              {@relationships
              |> Enum.at(@current_page - 1, [])
              |> List.first()
              |> Map.get(:src)
              |> Map.get(:name)}
            </b>
            <br /> causes...
          </.card_title>
        </.card_header>
        <.scroll_area class="overflow-y-auto h-72 grow shrink" id="relate-scroll-container">
          <.card_content class="flex items-center justify-between py-4 gap-2 text-sm flex-col p-2">
            <%= for rel <- @relationships|> Enum.at(@current_page - 1, []) do %>
              <div class="w-full border-b-[1px] border-gray-300 pt-4 pb-6 flex justify-center">
                <div class="flex items-center flex-col gap-2 mx-4 max-w-md grow">
                  <p class="font-bold">{rel.dst.name}</p>
                  <div class="flex gap-2 w-full">
                    <.button
                      variant="outline"
                      class={"font-normal hover:bg-orange-100 w-full #{if rel.voted? == "direct", do: "bg-orange-200 text-orange-900 border-0", else: ""}"}
                      value="direct"
                      id={"direct-" <> rel.id}
                      phx-click="vote"
                      phx-value-type="direct"
                      phx-value-src_id={rel.src.id}
                      phx-value-dst_id={rel.dst.id}
                      phx-target={@myself}
                    >
                      to increase
                      <div
                        class="h-4 w-4 transition-all ml-2"
                        style="mask: url('/images/direct.svg') no-repeat; -webkit-mask: url('/images/direct.svg') no-repeat; background-color: currentColor;"
                      />
                    </.button>
                    <.button
                      variant="outline"
                      class={"hover:bg-blue-100 font-normal w-full #{if rel.voted? == "inverse", do: "bg-blue-200 text-blue-900 border-0", else: ""}"}
                      value="inverse"
                      id={"inverse-" <> rel.id}
                      phx-click="vote"
                      phx-value-type="inverse"
                      phx-value-src_id={rel.src.id}
                      phx-value-dst_id={rel.dst.id}
                      phx-target={@myself}
                    >
                      to decrease <.icon name="hero-arrows-up-down" class="h-4 w-4 ml-2" />
                    </.button>
                  </div>
                  <.button
                    variant="outline"
                    class={"hover:bg-gray-100 font-normal w-full #{if rel.voted? == "no_relationship", do: "bg-gray-300 text-gray-700 border-0", else: ""}"}
                    value="no_relationship"
                    id={"no_relationship-" <> rel.id}
                    phx-click="vote"
                    phx-value-type="no_relationship"
                    phx-value-src_id={rel.src.id}
                    phx-value-dst_id={rel.dst.id}
                    phx-target={@myself}
                  >
                    no direct effect <.icon name="hero-no-symbol-solid" class="h-4 w-4 ml-2" />
                  </.button>
                </div>
              </div>
            <% end %>
          </.card_content>
        </.scroll_area>
      </.card>
      <div class="mt-4 flex" id="pagination-container" phx-hook="RelationshipScroll">
        <.pagination
          type="both_buttons"
          current_page={@current_page}
          total_pages={@total_pages}
          target={@myself}
          on_left_click="previous_page"
          on_right_click="next_page"
          left_disabled={@current_page == 1}
          right_disabled={@current_page == @total_pages}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"type" => type, "src_id" => src_id, "dst_id" => dst_id}, socket) do
    voter = socket.assigns.current_user

    case Ash.get(Revelo.Diagrams.Relationship, src_id: src_id, dst_id: dst_id) do
      {:ok, relationship} ->
        type = String.to_existing_atom(type)
        Diagrams.relationship_vote!(relationship, type, actor: voter)

        # TODO this partitions the thing each time and could be done better with a stream
        relationships =
          socket.assigns.session.id
          |> Diagrams.list_potential_relationships!(actor: socket.assigns.current_user)
          |> Enum.group_by(& &1.src.name)
          |> Map.values()
          |> then(fn relationships ->
            rotation = :erlang.phash2(socket.assigns.current_user.id, length(relationships))

            case rotation do
              0 -> relationships
              n -> Enum.slice(relationships, n..-1) ++ Enum.slice(relationships, 0..(n - 1))
            end
          end)

        vote_count =
          relationships
          |> List.flatten()
          |> Enum.count(&(&1.voted? != nil))

        ReveloWeb.Presence.update_relate_status(
          socket.assigns.session.id,
          socket.assigns.current_user.id,
          vote_count
        )

        {:noreply, assign(socket, relationships: relationships, vote_count: vote_count)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("previous_page", _, socket) do
    socket = update(socket, :current_page, &max(&1 - 1, 1))
    {:noreply, push_event(socket, "page_changed", %{})}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    socket = update(socket, :current_page, &min(&1 + 1, socket.assigns.total_pages))
    {:noreply, push_event(socket, "page_changed", %{})}
  end
end
