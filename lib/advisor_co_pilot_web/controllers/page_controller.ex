defmodule AdvisorCoPilotWeb.PageController do
  use AdvisorCoPilotWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
