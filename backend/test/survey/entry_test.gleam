import gleeunit/should
import survey/entry
import gleam/erlang/file

pub fn saving_test() {
  assert Ok(_) = file.recursive_delete("data")
  assert Ok("[\n  \n]") = entry.list_json()

  assert Ok(uuid) = entry.save([#("name", "Lucy"), #("magic", "true")])
  assert Ok(json) = entry.list_json()
  json
  |> should.equal(
    "[
  {\"id\":\"" <> uuid <> "\",\"name\":\"Lucy\",\"magic\":\"true\"}
]",
  )
}
