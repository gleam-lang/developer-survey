import gleam/json
import gleam/list
import gleam/result
import gleam/string
import ids/nanoid
import simplifile

const database = "data/entries.jsonl"

pub fn save(
  ip: String,
  answers: List(#(String, String)),
) -> Result(Nil, simplifile.FileError) {
  use _ <- result.try(ensure_data_directory_exists())
  let id = nanoid.generate()
  let json =
    answers
    |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) })
    |> list.key_set("id", json.string(id))
    |> list.key_set("ip", json.string(ip))
    |> list.key_set("inserted_at", json.string(current_timestamp()))
    |> json.object()
    |> json.to_string()
    |> string.append("\n")
  simplifile.append(json, database)
}

pub fn list_json() -> Result(String, simplifile.FileError) {
  use _ <- result.try(ensure_data_directory_exists())
  simplifile.read(database)
}

pub fn ensure_data_directory_exists() -> Result(Nil, simplifile.FileError) {
  case simplifile.create_directory("data") {
    Ok(_) -> Ok(Nil)
    Error(simplifile.Eexist) -> Ok(Nil)
    Error(other) -> Error(other)
  }
}

@external(erlang, "survey_ffi", "current_timestamp")
fn current_timestamp() -> String
