import gleam/http
import gleam/http/request
import gleam/result
import survey/entry
import wisp.{type Request, type Response}

pub fn handle_request(request: Request) -> Response {
  case request.path_segments(request) {
    ["entries"] -> entries(request)
    _ -> wisp.not_found()
  }
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn entries(request: Request) -> Response {
  use <- wisp.require_method(request, http.Post)
  use form <- wisp.require_form(request)

  let ip =
    request.get_header(request, "fly-client-ip")
    |> result.unwrap("")
  let assert Ok(_) = entry.save(ip, form.values)

  wisp.redirect("/?thank-you")
}
