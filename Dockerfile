FROM erlang:27.1.1.0-alpine AS build
COPY --from=ghcr.io/gleam-lang/gleam:v1.7.0-erlang-alpine /bin/gleam /bin/gleam
COPY . /app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
RUN \
  addgroup --system gleam_developer_survey && \
  adduser --system gleam_developer_survey -g gleam_developer_survey   
COPY --from=build /app/build/erlang-shipment /app
VOLUME /app/data
LABEL org.opencontainers.image.source=https://github.com/gleam-lang/developer-survey
LABEL org.opencontainers.image.description="Gleam Developer Survey web application"
LABEL org.opencontainers.image.licenses=Apache-2.0
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
