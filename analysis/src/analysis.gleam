//// A hacky script for processing the Gleam Developer Survey data.
//// Enjoy!

import gleam/erlang/file
import gleam/iterator
import gleam/dynamic
import gleam/string
import gleam/result
import gleam/json
import gleam/list
import gleam/map.{Map}
import gleam/int
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

  let count = fn(get: fn(Entry) -> List(String)) -> List(#(String, Int)) {
    entries
    |> list.flat_map(get)
    |> iterator.from_list
    |> iterator.group(fn(x) { x })
    |> map.map_values(fn(_, xs) { list.length(xs) })
    |> map.to_list
    |> list.sort(fn(x, y) { int.compare(x.1, y.1) })
    |> list.reverse
  }

  let _production_os_counts = count(fn(e) { e.production_os })
  let _development_os_counts = count(fn(e) { e.development_os })
  let _targets = count(fn(e) { e.targets })
  let _news_sources = count(fn(e) { e.news_sources })
  let _merchandise = count(fn(e) { e.merchandise })
  let _languages = count(fn(e) { e.languages })
  // anything_else: String,
  // company_size: String,
  // country: String,
  // duration_using_gleam: String,
  // first_heard_about_gleam: String,
  // gender: String,
  // gleam_future_additions: String,
  // gleam_usage: String,
  // id: String,
  // industry: String,
  // inserted_at: String,
  // ip: String,
  // professional_programming_experience: String,
  // programming_experience: String,
  // role: String,
  // sexual_orientation: String,
  // source: String,
  // transgender: String,
  // why_do_you_like_gleam: String,
  // age: Map(String, Int),
}

pub fn parse_jsonl(jsonl: String) {
  jsonl
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.try_map(json.decode(_, dynamic.map(dynamic.string, dynamic.string)))
}

fn normalise_merchandise(choice: String) -> List(String) {
  case choice {
    "T-shirts" -> ["T-shirts"]
    "Stickers" -> ["Stickers"]
    "Hoodies" -> ["Hoodies"]
    "Mugs" -> ["Mugs"]
    "Enamel pins" -> ["Enamel pins"]
    "Earings" -> ["Earings"]
    "Notepads" -> ["Notepads"]
    "Leggings" -> ["Leggings"]
    "socks" -> ["Socks"]
    "programming socks and a butt plug. it would be funny and I'd buy it. not trolling." -> [
      "Socks", "Butt plugs",
    ]
    "programming socks" -> ["Socks"]
    "hats" -> ["Hats"]
    "Temp tattoo" -> ["Temporary tattoos"]
    "Sweat pants with gleam on the butt" -> ["Sweat pants"]
    "Lucy Plush!" -> ["Plushies"]
    "None" | "" -> []
  }
}

fn normalise_news_source(source: String) -> List(String) {
  let contains_lobsters = string.contains(string.lowercase(source), "lobste")
  case source {
    "GitHub discussions" | "Watching the Gleam repo and reading release notes" -> [
      "GitHub",
    ]

    "gleam.run" | "RSS feed" | "gleam.run ...?" | "The website." | "Gleam website" | "The official homepage always has news about the lang changelov" -> [
      "gleam.run",
    ]

    "See it in passing on news.ycombinator.com and elixirforum.com" -> [
      "Hacker News", "Elixir Forum",
    ]

    "Occassional mentions on Mastodon or Lobste.rs or Hacker News" -> [
      "Hacker News", "Fediverse", "lobste.rs",
    ]

    "Elixirforum" | "elixirforum.com" -> ["Elixir Forum"]
    "erlangforums.com" -> ["Erlang Forums"]

    "news.ycombinator.com" | "Hacker News" | "HackerNews" -> ["Hacker News"]

    "Elm Slack" -> ["Elm Slack"]

    "elixir reddit" -> ["/r/elixir"]
    "r/programming" -> ["/r/programming"]
    "/r/programming or /r/elixir" -> ["/r/programming", "/r/elixir"]

    "The Gleam Discord server" -> ["The Gleam Discord Server"]
    "@gleamlang on Twitter" -> ["@gleamlang on Twitter"]
    "@louispilfold on Twitter" -> ["@louispilfold on Twitter"]
    "/r/gleamlang" -> ["/r/gleamlang"]

    "Louis" | "I'd just message Louis if I had a question" -> []

    _ if contains_lobsters -> ["lobste.rs"]
  }
}

fn normalise_target(target: String) -> List(String) {
  case target {
    "Erlang" -> ["Erlang"]
    "JavaScript" -> ["JavaScript"]
  }
}

fn normalise_os(os: String) -> List(String) {
  case os {
    "Embedded RTOS" | "Various RTOS and bare metal targets" -> ["Embedded RTOS"]
    "Containers / Kubernetes" | "WSL" -> ["Linux"]
    "illumos" | "Illumos" -> ["Illumos"]
    "Linux" -> ["Linux"]
    "macOS" -> ["macOS"]
    "Windows" -> ["Windows"]
    "iOS" -> ["iOS"]
    "Android" -> ["Android"]
    "FreeBSD" -> ["FreeBSD"]
    "OpenBSD" -> ["OpenBSD"]
    "I don't deploy to servers" -> []
  }
}

fn normalise_languages(language: String) -> List(String) {
  case language {
    "Ada" -> ["Ada"]
    "BQN" -> ["BQN"]
    "Bash" -> ["Bash"]
    "C" -> ["C"]
    "C#" -> ["C#"]
    "C++" -> ["C++"]
    "CSS" -> ["CSS"]
    "Clojure" -> ["Clojure"]
    "Crystal" -> ["Crystal"]
    "Dart" -> ["Dart"]
    "Elixir" -> ["Elixir"]
    "Elm" -> ["Elm"]
    "Erlang" -> ["Erlang"]
    "longtime F# hacker" | "F#" | "Fsharp" -> ["F#"]
    "GDScript" -> ["GDScript"]
    "Gleam!" | "Gleam" -> []
    "Go" -> ["Go"]
    "HTML" -> ["HTML"]
    "Haskell" -> ["Haskell"]
    "Jakt" -> ["Jakt"]
    "Java" -> ["Java"]
    "JavaScript" -> ["JavaScript"]
    "Julia" -> ["Julia"]
    "Kotlin" -> ["Kotlin"]
    "Lean" -> ["Lean"]
    "Lisp" -> ["Lisp"]
    "Mercury" -> ["Mercury"]
    "Nix" -> ["Nix"]
    "Nushell" -> ["Nushell"]
    "OCaml" -> ["OCaml"]
    "PHP" -> ["PHP"]
    "Perl" -> ["Perl"]
    "Prolog" -> ["Prolog"]
    "PureScript" -> ["PureScript"]
    "Python" -> ["Python"]
    "Racket" -> ["Racket"]
    "ReScript" -> ["ReScript"]
    "Ren" -> ["Ren"]
    "Rescript" -> ["Rescript"]
    "Ruby" -> ["Ruby"]
    "Rust" -> ["Rust"]
    "SML" -> ["SML"]
    "SQL" -> ["SQL"]
    "Scala" -> ["Scala"]
    "Shell" -> ["Shell"]
    "Swift" -> ["Swift"]
    "TypeScript" -> ["TypeScript"]
    "Zig" -> ["Zig"]
    "sh" -> ["sh"]
  }
}

fn normalise_entry(entry: JsonMap) {
  let #(entry, langauges) =
    pop_options(entry, "languages_used", normalise_languages)
  let #(entry, news_sources) =
    pop_options(entry, "news_sources_used", normalise_news_source)
  let #(entry, production_os) =
    pop_options(entry, "production_operating_system", normalise_os)
  let #(entry, development_os) =
    pop_options(entry, "development_operating_system", normalise_os)
  let #(entry, targets) = pop_options(entry, "targets_used", normalise_target)
  let #(entry, merchandise) =
    pop_options(entry, "merchandise", normalise_merchandise)

  let get = fn(key) { result.unwrap(map.get(entry, key), "") }

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

pub fn pop_options(
  data: JsonMap,
  prefix: String,
  normalise: fn(String) -> List(String),
) -> #(JsonMap, List(String)) {
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
    |> list.flat_map(normalise)
    |> list.sort(string.compare)
    |> list.unique

  let rest = map.drop(data, keys)
  #(rest, entries)
}
