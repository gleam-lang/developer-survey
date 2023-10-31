import gleeunit
import gleam/string
import gleam/http/response
import survey/router
import survey/entry
import wisp/testing
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn entry_ok_test() {
  let assert Ok(_) = entry.ensure_data_directory_exists()
  let assert Ok(_) = simplifile.delete("data")

  let form = [
    #("name", "Lucy"),
    #("species", "Star"),
    #("gender", "Non-binary"),
  ]

  let response = router.handle_request(testing.post_form("/entries", [], form))

  let assert 303 = response.status
  let assert Ok("/?thank-you") = response.get_header(response, "location")
  let assert Ok(json) = entry.list_json()
  let assert True = string.contains(json, "\"name\":\"Lucy\"")
  let assert True = string.contains(json, "\"species\":\"Star\"")
  let assert True = string.contains(json, "\"gender\":\"Non-binary\"")
}

pub fn not_found_test() {
  let response = router.handle_request(testing.get("/wibble", []))
  let assert 404 = response.status
}
