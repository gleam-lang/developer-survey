import gleeunit
import gleam/uri
import gleam/string
import gleam/http
import gleam/http/request
import gleam/http/response
import survey/routes.{router}
import survey/entry

pub fn main() {
  gleeunit.main()
}

pub fn entry_ok_test() {
  let body =
    uri.query_to_string([
      #("name", "Lucy"),
      #("species", "Star"),
      #("gender", "Non-binary"),
    ])

  let response =
    request.new()
    |> request.set_path("/entries")
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/x-www-form-urlencoded")
    |> router

  assert 303 = response.status
  assert Ok("/?thank-you") = response.get_header(response, "location")
  assert Ok(json) = entry.list_json()
  assert True =
    string.contains(
      json,
      "\"name\":\"Lucy\",\"species\":\"Star\",\"gender\":\"Non-binary\"",
    )
}

pub fn not_found_test() {
  let response =
    request.new()
    |> request.set_path("/wibble")
    |> router

  assert 404 = response.status
  assert Ok("text/plain") = response.get_header(response, "content-type")
}
