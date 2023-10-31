import gleam/erlang/file
import gleam/string
import survey/entry

pub fn saving_test() {
  let assert Ok(_) = entry.ensure_data_directory_exists()
  let assert Ok(_) = file.recursive_delete("data")

  let assert Ok(_) =
    entry.save("127.0.0.1", [#("name", "Lucy"), #("magic", "true")])

  let assert Ok(json) = entry.list_json()
  let assert True =
    string.contains(json, "\"name\":\"Lucy\",\"magic\":\"true\",\"id\":\"")
  let assert True = string.contains(json, "\"inserted_at\":\"")
}
