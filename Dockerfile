FROM ghcr.io/gleam-lang/gleam:v0.24.0-rc3-node-slim as frontend

COPY ./frontend /build

RUN \
  apt-get update \
  && apt-get install --yes ca-certificates \
  && cd /build \
  && npm ci \
  && gleam build \
  && npx parcel build src/index.html --dist-dir /app --no-source-maps

FROM ghcr.io/gleam-lang/gleam:v0.24.0-rc3-erlang-alpine

COPY ./backend /build/
COPY --from=frontend /app /build/backend/priv/static

RUN \
  cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && addgroup -S app \
  && adduser -S app -G app \
  && chown -R app /app

# Run the application
USER app
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
