defmodule AdvisorCoPilotWeb.PageControllerTest do
  use AdvisorCoPilotWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Prep, run, and review client meetings"
  end
end
