# 1. Build Stage
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.0
ARG DEBIAN_VERSION=bullseye-20240904-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-debian-${DEBIAN_VERSION} as builder

RUN apt-get update -y && apt-get install -y build-essential git && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/prod.exs ./config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.deploy
RUN mix compile

COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# 2. Runtime Stage
FROM debian:${DEBIAN_VERSION}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates libsqlite3-0 && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

# Copy the release from the builder stage
# This matches your :advisor_co_pilot app name
COPY --from=builder /app/_build/prod/rel/advisor_co_pilot ./

# Ensure the /data directory exists for the volume mount
RUN mkdir -p /data

CMD ["/app/bin/server"]