FROM ghcr.io/gleam-lang/gleam:v0.24.0-rc3-erlang-alpine

# Add project code
COPY . /build/

RUN \
  apk add --update --no-cache nodejs npm \
  && cd /build/frontend \
  && npm ci \
  && npm run build \
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
