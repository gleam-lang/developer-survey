import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/erlang/file
import gleam/string
import gleam/uri
import gleam/list
import gleam/json
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import survey/log_requests
import survey/static
import uuid

pub fn router(request: Request(String)) -> Response(String) {
  case request.path_segments(request) {
    ["entries"] -> entries(request)
    _ -> not_found()
  }
}

pub fn stack() -> Service(BitString, BitBuilder) {
  router
  |> string_body_middleware
  |> log_requests.middleware
  |> static.middleware()
  |> service.prepend_response_header("made-with", "Gleam")
}

pub fn string_body_middleware(
  service: Service(String, String),
) -> Service(BitString, BitBuilder) {
  fn(request: Request(BitString)) {
    case bit_string.to_string(request.body) {
      Ok(body) -> service(request.set_body(request, body))
      Error(_) -> bad_request()
    }
    |> response.map(bit_builder.from_string)
  }
}

fn entries(request: Request(String)) -> Response(String) {
  case request.method {
    http.Post -> create_entry(request)
    _ -> method_not_allowed()
  }
}

fn create_entry(request: Request(String)) -> Response(String) {
  assert Ok(uuid) = uuid.generate_v4()
  assert Ok(answers) = uri.parse_query(request.body)
  let json =
    json.object(list.map(answers, fn(pair) { #(pair.0, json.string(pair.1)) }))
  let path = string.concat(["data/", uuid, ".json"])
  assert Ok(_) = file.write(json.to_string(json), path)
  response.new(201)
  |> response.set_body(uuid)
}

fn method_not_allowed() -> Response(String) {
  response.new(405)
  |> response.set_body("Method not allowed")
  |> response.prepend_header("content-type", "text/plain")
}

fn not_found() -> Response(String) {
  response.new(404)
  |> response.set_body("Page not found")
  |> response.prepend_header("content-type", "text/plain")
}

fn bad_request() -> Response(String) {
  response.new(400)
  |> response.set_body("Bad request. Please try again")
  |> response.prepend_header("content-type", "text/plain")
}
