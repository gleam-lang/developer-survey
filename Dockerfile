FROM ghcr.io/gleam-lang/gleam:v0.26.1-erlang-alpine

# Add project code
COPY . /build/

RUN \
  apk add --update --no-cache nodejs npm \
  && cd /build/frontend \
  && npm ci \
  && gleam build \
  && npx parcel build src/index.html --dist-dir ../backend/priv/static --no-source-maps \
  && cd ../backend \
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
