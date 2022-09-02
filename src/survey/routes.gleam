import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import survey/log_requests
import survey/static

pub fn router(request: Request(String)) -> Response(String) {
  case request.path_segments(request) {
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
