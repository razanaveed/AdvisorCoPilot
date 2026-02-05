# ---------- Build stage ----------
FROM hexpm/elixir:1.15.8-erlang-26.2-debian-bookworm AS build

ENV MIX_ENV=prod
WORKDIR /app

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  nodejs \
  npm \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets assets
RUN cd assets && npm install && npm run build

COPY priv priv
COPY lib lib

RUN mix compile
RUN mix phx.digest
RUN mix release


# ---------- Runtime stage ----------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
  openssl \
  libstdc++6 \
  libncurses5 \
  ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8
WORKDIR /app

COPY --from=build /app/_build/prod/rel/advisor_copilot ./

ENV PHX_SERVER=true
ENV PORT=8080

CMD ["bin/advisor_copilot", "start"]
