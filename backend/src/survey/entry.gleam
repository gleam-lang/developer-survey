import gleam/erlang/file
import gleam/string
import gleam/json
import gleam/list
import uuid

const database = "data/entries.jsonl"

// TODO: add current timestamp
pub fn save(
  ip: String,
  answers: List(#(String, String)),
) -> Result(Nil, file.Reason) {
  try _ = ensure_data_directory_exists()
  assert Ok(uuid) = uuid.generate_v4()
  let json =
    answers
    |> list.filter(fn(pair) { pair.0 != "ip" || pair.0 != "id" })
    |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) })
    |> list.key_set("id", json.string(uuid))
    |> list.key_set("ip", json.string(ip))
    |> list.key_set("inserted_at", json.string(current_timestamp()))
    |> json.object()
    |> json.to_string()
    |> string.append("\n")
  file.append(json, database)
}

pub fn list_json() -> Result(String, file.Reason) {
  try _ = ensure_data_directory_exists()
  file.read(database)
}

pub fn ensure_data_directory_exists() -> Result(Nil, file.Reason) {
  case file.make_directory("data") {
    Ok(_) -> Ok(Nil)
    Error(file.Eexist) -> Ok(Nil)
    Error(other) -> Error(other)
  }
}

external fn current_timestamp() -> String =
  "survey_ffi" "current_timestamp"
