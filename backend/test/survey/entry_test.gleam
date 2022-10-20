import gleeunit/should
import survey/entry
import gleam/erlang/file

pub fn saving_test() {
  assert Ok(_) = entry.ensure_data_directory_exists()
  assert Ok(_) = file.recursive_delete("data")
  assert Ok("[\n  \n]") = entry.list_json()

  assert Ok(uuid) =
    entry.save("127.0.0.1", [#("name", "Lucy"), #("magic", "true")])
  assert Ok(json) = entry.list_json()
  json
  |> should.equal(
    "[
  {\"name\":\"Lucy\",\"magic\":\"true\",\"id\":\"" <> uuid <> "\",\"ip\":\"127.0.0.1\"}
]",
  )
}
