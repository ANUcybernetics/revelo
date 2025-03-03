defmodule ReveloWeb.SessionLive.RelationshipVotingComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  import ReveloWeb.Component.Card

  alias Revelo.Diagrams
  alias Revelo.Diagrams.Relationship

  @impl true
  def mount(socket) do
    {:ok, stream(socket, :relationships, [])}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Get all non-hidden variables for the session
    variables = Diagrams.list_variables!(assigns.session.id, false, actor: assigns.current_user)

    # Rotate the variables list by a pseudo-random amount based on user ID
    rotated_variables =
      case length(variables) do
        0 ->
          []

        len ->
          rotation = :erlang.phash2(assigns.current_user.id, len)

          case rotation do
            0 -> variables
            n -> Enum.slice(variables, n..-1//1) ++ Enum.slice(variables, 0..(n - 1))
          end
      end

    # Create a ZipperList with the cursor at the first element
    variables_zipper = %ZipperList{
      left: [],
      cursor: List.first(rotated_variables),
      right: Enum.slice(rotated_variables, 1..-1//1)
    }

    # Fetch relationships for the current cursor (src variable)
    socket =
      if variables_zipper.cursor do
        relationships =
          variables_zipper.cursor.id
          |> Diagrams.list_relationships_from_src!(actor: assigns.current_user)
          |> Enum.sort_by(fn rel -> rel.voted? != nil end)

        socket
        |> stream(:relationships, relationships, reset: true)
        |> assign(:variables, variables_zipper)
      else
        assign(socket, :variables, variables_zipper)
      end

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
              {if @variables.cursor, do: @variables.cursor.name, else: ""}
            </b>
            <br /> causes...
          </.card_title>
        </.card_header>
        <.scroll_area class="overflow-y-auto h-72 grow shrink" id="relate-scroll-container">
          <.card_content
            id="relationship-voting-stream"
            class="flex items-center justify-between py-4 gap-2 text-sm flex-col p-2"
            phx-update="stream"
          >
            <%= for {id, rel} <- @streams.relationships do %>
              <div class="w-full border-b-[1px] border-gray-300 pt-4 pb-6 flex justify-center" id={id}>
                <div class="flex items-center flex-col gap-2 mx-4 max-w-md grow">
                  <p class="font-bold">{rel.dst.name}</p>
                  <div class="flex gap-2 w-full">
                    <.button
                      variant="outline"
                      class={"font-normal hover:bg-orange-100 w-full #{if rel.voted? == "direct", do: "bg-orange-200 text-direct-foreground border-0", else: ""}"}
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
                      class={"hover:bg-inverse-light font-normal w-full #{if rel.voted? == "inverse", do: "bg-inverse text-inverse-foreground border-0", else: ""}"}
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
          current_page={if @variables.cursor, do: length(@variables.left) + 1, else: 1}
          total_pages={
            length(@variables.left) + if(@variables.cursor, do: 1, else: 0) + length(@variables.right)
          }
          target={@myself}
          on_left_click="previous_page"
          on_right_click="next_page"
          left_disabled={Enum.empty?(@variables.left)}
          right_disabled={Enum.empty?(@variables.right)}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"type" => type, "src_id" => src_id, "dst_id" => dst_id}, socket) do
    voter = socket.assigns.current_user

    case Ash.get(Relationship, src_id: src_id, dst_id: dst_id) do
      {:ok, relationship} ->
        type = String.to_existing_atom(type)
        Diagrams.relationship_vote!(relationship, type, actor: voter)

        relationship =
          Ash.get!(Relationship, [src_id: src_id, dst_id: dst_id],
            load: [:src, :dst, :voted?],
            actor: socket.assigns.current_user
          )

        socket = stream_insert(socket, :relationships, relationship)

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("previous_page", _, socket) do
    updated_zipper = ZipperList.left(socket.assigns.variables)

    if updated_zipper.cursor do
      # Fetch relationships for the new current variable
      relationships =
        updated_zipper.cursor.id
        |> Diagrams.list_relationships_from_src!(actor: socket.assigns.current_user)
        |> Enum.sort_by(fn rel -> rel.voted? != nil end)

      socket =
        socket
        |> stream(:relationships, relationships, reset: true)
        |> assign(:variables, updated_zipper)

      {:noreply, push_event(socket, "page_changed", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("next_page", _, socket) do
    updated_zipper = ZipperList.right(socket.assigns.variables)

    if updated_zipper.cursor do
      # Fetch relationships for the new current variable
      relationships =
        updated_zipper.cursor.id
        |> Diagrams.list_relationships_from_src!(actor: socket.assigns.current_user)
        |> Enum.sort_by(fn rel -> rel.voted? != nil end)

      socket =
        socket
        |> stream(:relationships, relationships, reset: true)
        |> assign(:variables, updated_zipper)

      {:noreply, push_event(socket, "page_changed", %{})}
    else
      {:noreply, socket}
    end
  end
end
