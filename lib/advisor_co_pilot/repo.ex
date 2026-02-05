defmodule AdvisorCoPilot.Repo do
  use Ecto.Repo,
    otp_app: :advisor_co_pilot,
    adapter: Ecto.Adapters.SQLite3
end
