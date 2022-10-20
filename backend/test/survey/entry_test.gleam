import gleam/erlang/file
import gleam/string
import survey/entry

pub fn saving_test() {
  assert Ok(_) = entry.ensure_data_directory_exists()
  assert Ok(_) = file.recursive_delete("data")

  assert Ok(_) =
    entry.save("127.0.0.1", [#("name", "Lucy"), #("magic", "true")])

  assert Ok(json) = entry.list_json()
  assert True =
    string.contains(json, "\"name\":\"Lucy\",\"magic\":\"true\",\"id\":\"")
}
