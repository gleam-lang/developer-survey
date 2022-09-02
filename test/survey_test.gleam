import gleeunit
import gleam/http/request
import gleam/http/response
import survey/routes.{router}

pub fn main() {
  gleeunit.main()
}

pub fn not_found_test() {
  let response =
    request.new()
    |> request.set_path("/wibble")
    |> router

  assert 404 = response.status
  assert Ok("text/plain") = response.get_header(response, "content-type")
}
