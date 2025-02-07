defmodule Revelo.UIComponentsTest do
  use ReveloWeb.ConnCase

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import ReveloTest.Generators

  test "sidebar contains icons (with links) for all stages of the session" do
    user = user()
    session = session(user)
    assigns = %{session_id: session.id, current_page: :prepare}
    html = render_component(&ReveloWeb.UIComponents.sidebar/1, assigns)

    assert html =~ "Add Session"
    assert html =~ "View All Sessions"
    assert html =~ "Prepare"
    assert html =~ "Identify"
    assert html =~ "Relate"
    assert html =~ "Analyse"
    assert html =~ "User"
  end

  test "sidebar contains just the top icon when no session present" do
    assigns = %{session_id: nil, current_page: :prepare}
    html = render_component(&ReveloWeb.UIComponents.sidebar/1, assigns)

    assert html =~ "Add Session"
    assert html =~ "View All Sessions"
    assert html =~ "User"
  end

  test "badge_key shows as key variable" do
    html = render_component(&ReveloWeb.UIComponents.badge_key/1, %{})
    assert html =~ "Key Variable"
  end

  test "badge_vote shows as important" do
    html = render_component(&ReveloWeb.UIComponents.badge_vote/1, %{})
    assert html =~ "Important"
  end

  test "badge_no_vote shows as not important" do
    html = render_component(&ReveloWeb.UIComponents.badge_no_vote/1, %{})
    assert html =~ "Not Important"
  end

  test "badge_reinforcing shows as reinforcing" do
    html = render_component(&ReveloWeb.UIComponents.badge_reinforcing/1, %{})
    assert html =~ "Reinforcing"
  end

  test "badge_balancing shows as balancing" do
    html = render_component(&ReveloWeb.UIComponents.badge_balancing/1, %{})
    assert html =~ "Balancing"
  end

  test "variable_actions shows action buttons" do
    user = user()
    session = session(user)
    variable = %{id: 1, is_key?: false, hidden?: false, vote_tally: 0}

    html =
      render_component(&ReveloWeb.UIComponents.variable_actions/1, %{
        variable: variable,
        session: session,
        live_action: :prepare
      })

    assert html =~ "Edit"
    assert html =~ "Make Key"
    assert html =~ "Delete"
  end

  test "task_completed shows completion status" do
    assigns = %{completed: 5, total: 10}
    html = render_component(&ReveloWeb.UIComponents.task_completed/1, assigns)
    assert html =~ "Task Completed!"
    assert html =~ "5/10"
  end

  test "variable_voting shows voting interface" do
    assigns = %{
      variables: [
        %{id: "1", name: "Test Var", is_key?: true, voted?: false},
        %{id: "2", name: "Other Var", is_key?: false, voted?: true}
      ],
      key_variable: "0"
    }

    html = render_component(&ReveloWeb.UIComponents.variable_voting/1, assigns)
    assert html =~ "Which of these are important parts of your system?"
    assert html =~ "Test Var"
  end

  test "variable_confirmation shows voting results" do
    assigns = %{
      variables: [%{id: "1", name: "Test Var", is_key?: true}],
      votes: [%{id: "1", voter_id: 1}],
      user_id: "1"
    }

    html = render_component(&ReveloWeb.UIComponents.variable_confirmation/1, assigns)
    assert html =~ "Your Variable Votes"
    assert html =~ "Test Var"
  end

  test "relationship_voting shows relationship options" do
    assigns = %{
      variable1: %{name: "Var 1"},
      variable2: %{name: "Var 2"}
    }

    html = render_component(&ReveloWeb.UIComponents.relationship_voting/1, assigns)
    assert html =~ "Pick the most accurate relation"
    assert html =~ "Var 1"
    assert html =~ "Var 2"
  end

  test "countdown shows timer" do
    assigns = %{time_left: 120, initial_time: 300, type: "both_buttons"}
    html = render_component(&ReveloWeb.UIComponents.countdown/1, assigns)
    assert html =~ "02:00"
    assert html =~ "remaining"
  end

  test "discussion shows feedback loop details" do
    assigns = %{
      loop_id: 1,
      title: "Test Loop",
      type: "reinforcing",
      variables: [%{id: "1", name: "Test Var", is_key?: true}],
      loop: [%{src: "1"}],
      description: "Test description"
    }

    html = render_component(&ReveloWeb.UIComponents.discussion/1, assigns)
    assert html =~ "Test Loop"
    assert html =~ "Test Var"
    assert html =~ "Test description"
  end

  test "modal creates modal dialog" do
    assigns = %{id: "test-modal", show: true}

    html =
      rendered_to_string(~H"""
      <ReveloWeb.UIComponents.modal id={@id}>
        Modal content
      </ReveloWeb.UIComponents.modal>
      """)

    assert html =~ "Modal content"
  end

  test "qr_code creates QR code" do
    assigns = %{text: "https://example.com"}
    html = render_component(&ReveloWeb.UIComponents.qr_code/1, assigns)
    assert html =~ "<img"
  end
end
