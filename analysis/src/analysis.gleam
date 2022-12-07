//// A hacky script for processing the Gleam Developer Survey data.
//// Enjoy!

import gleam/erlang/file
import gleam/dynamic
import gleam/string
import gleam/result
import gleam/json
import gleam/list
import gleam/map.{Map}
import gleam/io

pub type Entry {
  Entry(
    production_os: List(String),
    development_os: List(String),
    targets: List(String),
    merchandise: List(String),
    news_sources: List(String),
    languages: List(String),
    age: String,
    anything_else: String,
    company_size: String,
    country: String,
    duration_using_gleam: String,
    first_heard_about_gleam: String,
    gender: String,
    gleam_future_additions: String,
    gleam_usage: String,
    id: String,
    industry: String,
    inserted_at: String,
    ip: String,
    professional_programming_experience: String,
    programming_experience: String,
    role: String,
    sexual_orientation: String,
    source: String,
    transgender: String,
    why_do_you_like_gleam: String,
  )
}

pub type JsonMap =
  Map(String, String)

pub fn main() {
  assert Ok(contents) = file.read("2022.jsonl")
  assert Ok(entries) = parse_jsonl(contents)
  let entries = list.map(entries, normalise_entry)
  list.map(entries, io.debug)
}

pub fn parse_jsonl(jsonl: String) {
  jsonl
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.try_map(json.decode(_, dynamic.map(dynamic.string, dynamic.string)))
}

fn normalise_entry(entry: JsonMap) {
  let #(entry, langauges) = pop_options(entry, "languages_used")
  let #(entry, news_sources) = pop_options(entry, "news_sources_used")
  let #(entry, production_os) =
    pop_options(entry, "production_operating_system")
  let #(entry, development_os) =
    pop_options(entry, "development_operating_system")
  let #(entry, targets) = pop_options(entry, "targets_used")
  let #(entry, merchandise) = pop_options(entry, "merchandise")

  let get = fn(key) { result.unwrap(map.get(entry, key), "") }

  // io.debug(langauges)
  Entry(
    production_os: production_os,
    development_os: development_os,
    targets: targets,
    merchandise: merchandise,
    news_sources: news_sources,
    languages: langauges,
    age: get("age"),
    anything_else: get("anything_else"),
    company_size: get("company_size"),
    country: get("country"),
    duration_using_gleam: get("duration_using_gleam"),
    first_heard_about_gleam: get("first_heard_about_gleam"),
    gender: get("gender"),
    gleam_future_additions: get("gleam_future_additions"),
    gleam_usage: get("gleam_usage"),
    id: get("id"),
    industry: get("industry"),
    inserted_at: get("inserted_at"),
    ip: get("ip"),
    professional_programming_experience: get(
      "professional_programming_experience",
    ),
    programming_experience: get("programming_experience"),
    role: get("role"),
    sexual_orientation: get("sexual_orientation"),
    source: get("source"),
    transgender: get("transgender"),
    why_do_you_like_gleam: get("why_do_you_like_gleam"),
  )
}

pub fn pop_options(data: JsonMap, prefix: String) -> #(JsonMap, List(String)) {
  let keys =
    data
    |> map.keys
    |> list.filter(string.starts_with(_, prefix))

  let matching = map.take(data, keys)
  let matching = case map.get(matching, prefix <> "_other") {
    Ok(other) -> {
      let others =
        other
        |> string.split(",")
        |> list.map(string.trim)
        |> list.map(fn(x) { prefix <> "[" <> x <> "]" })
        |> list.map(fn(x) { #(x, "on") })
        |> map.from_list
      matching
      |> map.drop([prefix <> "[Other (please specify)]", prefix <> "_other"])
      |> map.merge(others)
    }
    Error(Nil) -> matching
  }

  let entries =
    matching
    |> map.keys
    |> list.map(fn(x) { string.replace(x, prefix <> "[", "") })
    |> list.map(fn(x) { string.replace(x, "]", "") })
    |> list.sort(string.compare)

  let rest = map.drop(data, keys)
  #(rest, entries)
}
