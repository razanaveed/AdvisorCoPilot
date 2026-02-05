alias AdvisorCoPilot.Repo
alias AdvisorCoPilot.Meetings.Meeting

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This will create a small set of demo meetings that you can use
# with the Prep and Live Meeting flows.

Repo.delete_all(Meeting)

now = DateTime.utc_now() |> DateTime.truncate(:second)

_prep_meeting =
  Repo.insert!(%Meeting{
    client_name: "Alex Johnson",
    client_id: "client-001",
    status: "prep",
    transcript: nil,
    inserted_at: now,
    updated_at: now
  })

_live_meeting =
  Repo.insert!(%Meeting{
    client_name: "Morgan Smith",
    client_id: "client-002",
    status: "prep",
    transcript: nil,
    inserted_at: now,
    updated_at: now
  })

_completed_meeting =
  Repo.insert!(%Meeting{
    client_name: "Taylor Lee",
    client_id: "client-003",
    status: "completed",
    transcript:
      "We discussed retirement at 60, education funding, and their preference for a balanced risk profile.",
    inserted_at: now,
    updated_at: now
  })

IO.puts("Seeded demo meetings into SQLite.")

