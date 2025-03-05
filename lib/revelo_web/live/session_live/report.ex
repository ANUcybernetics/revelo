defmodule ReveloWeb.SessionLive.Report do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@current_user.facilitator?} class="h-full flex flex-col h-svh">
      <!-- Top Navbar -->
      <header class="border-b sticky top-0 z-0 bg-white">
        <div class="container flex items-center justify-between p-4">
          <div class="flex items-center gap-4">
            <h1 class="text-lg font-semibold">{@session.name} Report</h1>
          </div>
          <div class="flex items-center gap-3">
            <.button variant="outline" phx-click="preview_report">
              <.icon name="hero-eye-mini" class="h-4 w-4 mr-2" /> Preview
            </.button>
            <.button variant="outline" phx-click="export_pdf">
              <.icon name="hero-document-arrow-down-mini" class="h-4 w-4 mr-2" /> Export PDF
            </.button>
            <.button phx-click="generate_report">
              <.icon name="hero-sparkles-mini" class="h-4 w-4 mr-2" /> Generate Report
            </.button>
          </div>
        </div>
      </header>
      
    <!-- Content Area -->
      <div class="flex-1 overflow-y-auto w-full max-w-full">
        <div class="container p-6 mx-auto">
          <.tabs :let={builder} default="prepare" id="report-sections" class="mb-6">
            <.tabs_list class="grid w-full grid-cols-5">
              <.tabs_trigger builder={builder} value="prepare">Prepare</.tabs_trigger>
              <.tabs_trigger builder={builder} value="identify">Identify</.tabs_trigger>
              <.tabs_trigger builder={builder} value="relate">Relate</.tabs_trigger>
              <.tabs_trigger builder={builder} value="analyse">Analyse</.tabs_trigger>
              <.tabs_trigger builder={builder} value="preview">Preview</.tabs_trigger>
            </.tabs_list>

            <.tabs_content value="prepare">
              <.card class="mb-6">
                <.card_header>
                  <.card_title>Problem Description</.card_title>
                  <.card_description>
                    Summarize the core problem addressed in the session
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="prepare-summary"
                    name="prepare_summary"
                    placeholder="Describe the problem that was addressed in this session..."
                    value={@prepare_summary}
                    phx-change="update_prepare_summary"
                  />
                </.card_content>
              </.card>

              <.card>
                <.card_header>
                  <.card_title>Session Setup and Goals</.card_title>
                  <.card_description>
                    Outline the main objectives and how the session was structured
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="prepare-goals"
                    name="prepare_goals"
                    placeholder="Describe the goals of the session and how it was set up..."
                    value={@prepare_goals}
                    phx-change="update_prepare_goals"
                  />
                </.card_content>
              </.card>
            </.tabs_content>

            <.tabs_content value="identify">
              <.card class="mb-6">
                <.card_header>
                  <.card_title>Variable Selection Analysis</.card_title>
                  <.card_description>
                    Analyze which variables were included and excluded
                  </.card_description>
                </.card_header>
                <.card_content>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <h3 class="text-sm font-medium mb-2">Included Variables</h3>
                      <.textarea
                        id="identify-included"
                        name="identify_included"
                        placeholder="Describe key included variables and why they matter..."
                        value={@identify_included}
                        phx-change="update_identify_included"
                      />
                    </div>
                    <div>
                      <h3 class="text-sm font-medium mb-2">Excluded Variables</h3>
                      <.textarea
                        id="identify-excluded"
                        name="identify_excluded"
                        placeholder="Describe key excluded variables and the reasoning..."
                        value={@identify_excluded}
                        phx-change="update_identify_excluded"
                      />
                    </div>
                  </div>
                </.card_content>
              </.card>

              <.card>
                <.card_header>
                  <.card_title>Voting Patterns</.card_title>
                  <.card_description>
                    Analyze how participants prioritized different variables
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="identify-voting"
                    name="identify_voting"
                    placeholder="Describe the voting patterns and what they reveal about participants' priorities..."
                    value={@identify_voting}
                    phx-change="update_identify_voting"
                  />
                </.card_content>
              </.card>
            </.tabs_content>

            <.tabs_content value="relate">
              <.card class="mb-6">
                <.card_header>
                  <.card_title>Relationship Agreement</.card_title>
                  <.card_description>
                    Summarize relationships with strong consensus
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="relate-agreement"
                    name="relate_agreement"
                    placeholder="Describe relationships that participants strongly agreed on..."
                    value={@relate_agreement}
                    phx-change="update_relate_agreement"
                  />
                </.card_content>
              </.card>

              <.card>
                <.card_header>
                  <.card_title>Relationship Disagreement</.card_title>
                  <.card_description>
                    Analyze relationships with significant disagreement
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="relate-disagreement"
                    name="relate_disagreement"
                    placeholder="Describe relationships with significant disagreement and how these were resolved..."
                    value={@relate_disagreement}
                    phx-change="update_relate_disagreement"
                  />
                </.card_content>
              </.card>
            </.tabs_content>

            <.tabs_content value="analyse">
              <.card class="mb-6">
                <.card_header>
                  <.card_title>System Dynamics Overview</.card_title>
                  <.card_description>
                    Summarize the overall system structure and key dynamics
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="analyse-overview"
                    name="analyse_overview"
                    placeholder="Describe the overall system structure and key dynamics identified..."
                    value={@analyse_overview}
                    phx-change="update_analyse_overview"
                  />
                </.card_content>
              </.card>

              <.card class="mb-6">
                <.card_header>
                  <.card_title>Feedback Loop Analysis</.card_title>
                  <.card_description>
                    Detail key feedback loops and their implications
                  </.card_description>
                </.card_header>
                <.card_content>
                  <div id="feedback-loops" class="space-y-4">
                    <div
                      :for={{id, loop} <- @feedback_loops}
                      id={"loop-#{id}"}
                      class="border rounded-md p-4"
                    >
                      <div class="flex justify-between mb-2">
                        <h3 class="text-sm font-medium">Feedback Loop {id}</h3>
                        <button
                          phx-click="remove_loop"
                          phx-value-id={id}
                          class="text-red-500 text-sm hover:underline"
                        >
                          Remove
                        </button>
                      </div>
                      <.textarea
                        id={"loop-description-#{id}"}
                        name="loop_description"
                        placeholder="Describe this feedback loop..."
                        value={loop.description}
                        phx-change="update_loop_description"
                        phx-value-id={id}
                      />
                      <div class="grid grid-cols-3 gap-2 mt-2">
                        <div>
                          <label class="text-xs font-medium block mb-1">Variables to Add</label>
                          <.textarea
                            id={"loop-variables-#{id}"}
                            name="loop_variables"
                            placeholder="Missing variables..."
                            value={loop.variables}
                            phx-change="update_loop_variables"
                            phx-value-id={id}
                          />
                        </div>
                        <div>
                          <label class="text-xs font-medium block mb-1">Realism Assessment</label>
                          <.textarea
                            id={"loop-realism-#{id}"}
                            name="loop_realism"
                            placeholder="Is this dynamic realistic?..."
                            value={loop.realism}
                            phx-change="update_loop_realism"
                            phx-value-id={id}
                          />
                        </div>
                        <div>
                          <label class="text-xs font-medium block mb-1">Implications</label>
                          <.textarea
                            id={"loop-implications-#{id}"}
                            name="loop_implications"
                            placeholder="Key implications..."
                            value={loop.implications}
                            phx-change="update_loop_implications"
                            phx-value-id={id}
                          />
                        </div>
                      </div>
                    </div>
                    <.button variant="outline" phx-click="add_feedback_loop" class="w-full">
                      <.icon name="hero-plus-mini" class="h-4 w-4 mr-2" /> Add Feedback Loop
                    </.button>
                  </div>
                </.card_content>
              </.card>

              <.card>
                <.card_header>
                  <.card_title>Recommendations</.card_title>
                  <.card_description>
                    Provide actionable recommendations based on the findings
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.textarea
                    id="analyse-recommendations"
                    name="analyse_recommendations"
                    placeholder="Provide recommendations based on the findings..."
                    value={@analyse_recommendations}
                    phx-change="update_analyse_recommendations"
                  />
                </.card_content>
              </.card>
            </.tabs_content>

            <.tabs_content value="preview">
              <.card>
                <.card_header>
                  <.card_title>Report Preview</.card_title>
                  <.card_description>
                    Preview how your report will look when generated
                  </.card_description>
                </.card_header>
                <.card_content>
                  <div class="prose max-w-none">
                    <h1>{@session.name} - Session Report</h1>

                    <h2>Problem Overview</h2>
                    <p>{@prepare_summary || "No problem description available."}</p>

                    <h2>Session Goals</h2>
                    <p>{@prepare_goals || "No session goals available."}</p>

                    <h2>Variable Analysis</h2>
                    <h3>Included Variables</h3>
                    <p>{@identify_included || "No analysis of included variables available."}</p>

                    <h3>Excluded Variables</h3>
                    <p>{@identify_excluded || "No analysis of excluded variables available."}</p>

                    <h3>Voting Patterns</h3>
                    <p>{@identify_voting || "No voting pattern analysis available."}</p>

                    <h2>Relationship Analysis</h2>
                    <h3>Areas of Agreement</h3>
                    <p>{@relate_agreement || "No relationship agreement analysis available."}</p>

                    <h3>Areas of Disagreement</h3>
                    <p>
                      {@relate_disagreement || "No relationship disagreement analysis available."}
                    </p>

                    <h2>System Dynamics</h2>
                    <p>{@analyse_overview || "No system dynamics overview available."}</p>

                    <h2>Feedback Loops</h2>
                    <div :for={{id, loop} <- @feedback_loops} class="mb-6">
                      <h3>Feedback Loop {id}</h3>
                      <p>{loop.description || "No description available."}</p>

                      <h4>Variables to Consider Adding</h4>
                      <p>{loop.variables || "None identified."}</p>

                      <h4>Realism Assessment</h4>
                      <p>{loop.realism || "No assessment available."}</p>

                      <h4>Implications</h4>
                      <p>{loop.implications || "No implications identified."}</p>
                    </div>

                    <h2>Recommendations</h2>
                    <p>{@analyse_recommendations || "No recommendations available."}</p>
                  </div>
                </.card_content>
              </.card>
            </.tabs_content>
          </.tabs>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:prepare_summary, nil)
      |> assign(:prepare_goals, nil)
      |> assign(:identify_included, nil)
      |> assign(:identify_excluded, nil)
      |> assign(:identify_voting, nil)
      |> assign(:relate_agreement, nil)
      |> assign(:relate_disagreement, nil)
      |> assign(:analyse_overview, nil)
      |> assign(:analyse_recommendations, nil)
      |> assign(:feedback_loops, %{
        1 => %{description: nil, variables: nil, realism: nil, implications: nil}
      })

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id}, _url, socket) do
    session = Ash.get!(Session, session_id)
    current_user = Ash.load!(socket.assigns.current_user, facilitator?: [session_id: session_id])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")
    end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:session, session)
      |> assign(:page_title, "Session Report")

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_report", _params, socket) do
    # This will be implemented later
    {:noreply, put_flash(socket, :info, "Report generation initiated")}
  end

  @impl true
  def handle_event("preview_report", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("export_pdf", _params, socket) do
    {:noreply, put_flash(socket, :info, "PDF export initiated")}
  end

  @impl true
  def handle_event("update_prepare_summary", %{"value" => value}, socket) do
    {:noreply, assign(socket, :prepare_summary, value)}
  end

  @impl true
  def handle_event("update_prepare_goals", %{"value" => value}, socket) do
    {:noreply, assign(socket, :prepare_goals, value)}
  end

  @impl true
  def handle_event("update_identify_included", %{"value" => value}, socket) do
    {:noreply, assign(socket, :identify_included, value)}
  end

  @impl true
  def handle_event("update_identify_excluded", %{"value" => value}, socket) do
    {:noreply, assign(socket, :identify_excluded, value)}
  end

  @impl true
  def handle_event("update_identify_voting", %{"value" => value}, socket) do
    {:noreply, assign(socket, :identify_voting, value)}
  end

  @impl true
  def handle_event("update_relate_agreement", %{"value" => value}, socket) do
    {:noreply, assign(socket, :relate_agreement, value)}
  end

  @impl true
  def handle_event("update_relate_disagreement", %{"value" => value}, socket) do
    {:noreply, assign(socket, :relate_disagreement, value)}
  end

  @impl true
  def handle_event("update_analyse_overview", %{"value" => value}, socket) do
    {:noreply, assign(socket, :analyse_overview, value)}
  end

  @impl true
  def handle_event("update_analyse_recommendations", %{"value" => value}, socket) do
    {:noreply, assign(socket, :analyse_recommendations, value)}
  end

  @impl true
  def handle_event("add_feedback_loop", _params, socket) do
    loops = socket.assigns.feedback_loops

    new_id =
      if Enum.empty?(loops),
        do: 1,
        else: (loops |> Enum.max_by(fn {id, _} -> id end) |> elem(0)) + 1

    updated_loops =
      Map.put(loops, new_id, %{description: nil, variables: nil, realism: nil, implications: nil})

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end

  @impl true
  def handle_event("remove_loop", %{"id" => id}, socket) do
    id = String.to_integer(id)
    updated_loops = Map.delete(socket.assigns.feedback_loops, id)

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end

  @impl true
  def handle_event("update_loop_description", %{"value" => value, "id" => id}, socket) do
    id = String.to_integer(id)
    loop = socket.assigns.feedback_loops[id]
    updated_loop = %{loop | description: value}
    updated_loops = Map.put(socket.assigns.feedback_loops, id, updated_loop)

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end

  @impl true
  def handle_event("update_loop_variables", %{"value" => value, "id" => id}, socket) do
    id = String.to_integer(id)
    loop = socket.assigns.feedback_loops[id]
    updated_loop = %{loop | variables: value}
    updated_loops = Map.put(socket.assigns.feedback_loops, id, updated_loop)

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end

  @impl true
  def handle_event("update_loop_realism", %{"value" => value, "id" => id}, socket) do
    id = String.to_integer(id)
    loop = socket.assigns.feedback_loops[id]
    updated_loop = %{loop | realism: value}
    updated_loops = Map.put(socket.assigns.feedback_loops, id, updated_loop)

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end

  @impl true
  def handle_event("update_loop_implications", %{"value" => value, "id" => id}, socket) do
    id = String.to_integer(id)
    loop = socket.assigns.feedback_loops[id]
    updated_loop = %{loop | implications: value}
    updated_loops = Map.put(socket.assigns.feedback_loops, id, updated_loop)

    {:noreply, assign(socket, :feedback_loops, updated_loops)}
  end
end
