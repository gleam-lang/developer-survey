FROM erlang:27.1.1.0-alpine AS build
COPY --from=ghcr.io/gleam-lang/gleam:v1.5.1-erlang-alpine /bin/gleam /bin/gleam
COPY . /app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
COPY --from=build /app/build/erlang-shipment /app
VOLUME /app/data
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
