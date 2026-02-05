# STEP 1: Use a blueprint that DEFINITELY exists
FROM hexpm/elixir:1.15.8-erlang-26.2.1-debian-bookworm-20240130-slim as builder

# Install build tools
RUN apt-get update -y && apt-get install -y build-essential git && apt-get clean

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
COPY config config
RUN mix deps.compile

# Build the app
COPY priv priv
COPY lib lib
COPY assets assets
RUN mix compile
RUN mix release

# STEP 2: The actual runner
FROM debian:bookworm-slim
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates libsqlite3-0 && apt-get clean

WORKDIR "/app"
# Matches your app name: advisor_co_pilot
COPY --from=builder /app/_build/prod/rel/advisor_co_pilot ./

RUN mkdir -p /data
CMD ["/app/bin/server"]