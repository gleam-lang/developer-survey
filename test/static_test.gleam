import survey/static
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/bit_builder.{BitBuilder}

fn stack() {
  test_service
  |> static.middleware
}

fn test_service(_request: Request(t)) -> Response(BitBuilder) {
  Response(418, [], bit_builder.from_string("I'm a teapot"))
}

pub fn non_matching_fall_through_test() {
  let response =
    request.new()
    |> request.set_path("wibble")
    |> stack()

  assert 418 = response.status
}

pub fn homepage_is_served_test() {
  let response =
    request.new()
    |> request.set_path("/")
    |> stack()

  assert 200 = response.status
  assert Ok("text/html") = response.get_header(response, "content-type")
}

pub fn styles_are_served_test() {
  let response =
    request.new()
    |> request.set_path("/styles.css")
    |> stack()

  assert 200 = response.status
  assert Ok("text/css") = response.get_header(response, "content-type")
}

pub fn dotdot_is_ineffective_test() {
  let response =
    request.new()
    |> request.set_path("../../gleam.toml")
    |> stack()

  assert 418 = response.status
}
