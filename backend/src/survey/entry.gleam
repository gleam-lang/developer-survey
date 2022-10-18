import gleam/erlang/file
import gleam/json
import gleam/list
import gleam/string
import uuid

// TODO: add current timestamp
pub fn save(answers: List(#(String, String))) -> Result(String, file.Reason) {
  try _ = ensure_data_directory_exists()
  assert Ok(uuid) = uuid.generate_v4()
  let answers = list.map(answers, fn(pair) { #(pair.0, json.string(pair.1)) })
  let json = json.object([#("id", json.string(uuid)), ..answers])
  let path = "data/" <> uuid <> ".json"
  try _ = file.write(json.to_string(json), path)
  Ok(uuid)
}

pub fn list_json() -> Result(String, file.Reason) {
  try _ = ensure_data_directory_exists()
  try files = file.list_directory("data")
  try entries = list.try_map(files, read_from_data_directory)
  let json = "[\n  " <> string.join(entries, ",\n  ") <> "\n]"
  Ok(json)
}

fn ensure_data_directory_exists() -> Result(Nil, file.Reason) {
  case file.make_directory("data") {
    Ok(_) -> Ok(Nil)
    Error(file.Eexist) -> Ok(Nil)
    Error(other) -> Error(other)
  }
}

fn read_from_data_directory(path: String) -> Result(String, file.Reason) {
  file.read("data/" <> path)
}
