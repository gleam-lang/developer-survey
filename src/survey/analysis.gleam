import filepath
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/function
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub const fields = [
  "anything-else", "country", "development-os", "gleam-experience",
  "gleam-in-production", "gleam-open-source", "gleam-user", "id", "improvements",
  "individual-sponsor", "inserted-at", "ip", "job-role", "likes", "news-sources",
  "organisation-name", "organisation-size", "organisation-sponsor",
  "other-languages", "production-os", "professional-experience", "projects",
  "runtimes", "sponsor-motivation", "targets",
]

pub const summary = "tmp/summary.md"

pub fn analyse(path: String) -> Nil {
  let assert Ok(_) = simplifile.delete_all(["tmp/responses"])
  let assert Ok(_) = simplifile.create_directory_all("tmp/responses")
  let assert Ok(_) = simplifile.write(summary, "# Summary\n\n")
  let assert Ok(files) = simplifile.read_directory(path)
  let data =
    parse(path, files)
    |> list.map(normalise_country)
    |> list.map(normalise_os(_, "development-os"))
    |> list.map(normalise_os(_, "production-os"))
    |> list.map(normalise_news)
    |> list.map(
      normalise_field(_, "gleam-experience", fn(x) {
        case x {
          "00" -> "0"
          x -> x
        }
      }),
    )

  // "gleam-open-source", "gleam-user",
  // "individual-sponsor", "inserted-at", "ip", "job-role", 
  // "organisation-name", "organisation-size", "organisation-sponsor",
  // "other-languages", "production-os", "professional-experience"

  add_counts(data, "Gleam user", "gleam-user", yes)
  add_counts(data, "Gleam in production", "gleam-in-production", yes)

  add_counts(data, "News sources", "news-sources", yes)

  add_counts(data, "Country", "country", yes)
  add_counts(data, "Country (Prod users)", "country", in_prod)

  add_counts(data, "Dev OS", "development-os", yes)
  add_counts(data, "Dev OS (Prod users)", "development-os", in_prod)

  add_counts(data, "Prod OS", "production-os", yes)
  add_counts(data, "Prod OS (Prod users)", "production-os", in_prod)

  add_counts(data, "Prod OS", "production-os", yes)
  add_counts(data, "Prod OS (Prod users)", "production-os", in_prod)

  add_counts(data, "Career", "professional-experience", yes)
  add_counts(data, "Career (Prod users)", "professional-experience", in_prod)

  add_counts(data, "Years of Gleam", "gleam-experience", yes)
  add_counts(data, "Years of Gleam (Prod users)", "gleam-experience", in_prod)

  add_counts(data, "Targets used", "targets", yes)
  add_counts(data, "Targets used (Prod users)", "targets", in_prod)

  add_counts(data, "Runtimes used", "runtimes", yes)
  add_counts(data, "Runtimes used (Prod users)", "runtimes", in_prod)

  add_counts(data, "Project types", "projects", yes)
  add_counts(data, "Project types (Prod users)", "projects", in_prod)

  write_response_summaries(data)

  let assert Ok(summary) = simplifile.read(summary)
  io.print(summary)

  get_all_for_field(data, "organisation-name") |> io.debug

  Nil
}

fn yes(_: c) -> Bool {
  True
}

fn in_prod(data: Dict(String, String)) -> Bool {
  dict.get(data, "gleam-in-production") == Ok("true")
}

fn add_counts(
  responses: List(Dict(String, String)),
  title: String,
  field_name: String,
  filter: fn(Dict(String, String)) -> Bool,
) -> Nil {
  responses
  |> list.filter(filter)
  |> tally(field_name)
  |> markdown_count_list
  |> append_summary_section(title)
}

fn append_summary_section(data: String, title: String) -> Nil {
  let assert Ok(_) =
    simplifile.append(summary, "## " <> title <> "\n\n" <> data <> "\n")
  Nil
}

fn tally(
  responses: List(Dict(String, String)),
  field_name: String,
) -> List(#(String, Int)) {
  responses
  |> list.map(dict.get(_, field_name))
  |> list.map(result.unwrap(_, ""))
  |> list.flat_map(string.split(_, ","))
  |> list.filter(fn(x) { x != "" })
  |> list.group(function.identity)
  |> dict.to_list
  |> list.map(fn(pair) { #(pair.0, list.length(pair.1)) })
  |> list.sort(fn(a, b) {
    int.compare(b.1, a.1) |> order.break_tie(string.compare(a.0, b.0))
  })
}

fn markdown_count_list(data: List(#(String, Int))) -> String {
  data
  |> list.map(fn(pair) { pair.0 <> ": " <> int.to_string(pair.1) })
  |> markdown_list
}

fn markdown_list(data: List(String)) -> String {
  data
  |> list.map(fn(data) { "- " <> data <> "\n" })
  |> string.concat
}

fn normalise_field(
  response: Dict(a, b),
  field_name: a,
  normaliser: fn(b) -> b,
) -> Dict(a, b) {
  case dict.get(response, field_name) {
    Ok(answer) -> {
      answer
      |> normaliser
      |> dict.insert(response, field_name, _)
    }
    Error(_) -> response
  }
}

fn normalise_news(response: Dict(String, String)) -> Dict(String, String) {
  use source <- normalise_multi_field(response, "news-sources")
  case source {
    "gleam.run" <> _
    | "Gleam blog"
    | "blog"
    | "Official Site"
    | "Official page"
    | "Official website"
    | "Official site"
    | "Here"
    | "Gleam Blog"
    | "gleam news"
    | "Gleam Website"
    | "RSS"
    | "Website"
    | "Gleam News Log"
    | "Gleam web site"
    | "https://gleam.run" <> _
    | "Gleam website"
    | "Gleam.run"
    | "Gleam.run RSS feed"
    | "here"
    | "website"
    | "packages.gleam.run"
    | "official website"
    | "this site :)" -> ["gleam.run"]

    "Tech YouTubers"
    | "Some youtube video" <> _
    | "Louis YT" <> _
    | "Isaac HH" <> _
    | "Louis stream" <> _
    | "Louis' stream" <> _
    | "Louis' Youtube" <> _
    | "https://m.youtube.com" <> _
    | "some youtube " <> _
    | "Youtube" <> _
    | "YouTube" <> _
    | "youtube" <> _
    | "Gleam creator's YT channel" <> _
    | "tech youtubers" -> ["YouTube"]

    "The Gleam Weekly" <> _
    | "Gleam Weekly" <> _
    | "GleamWeekly" <> _
    | "Mailing list" <> _
    | "CrowdHailer newsletter" <> _
    | "Newletter" <> _
    | "Gleam weekly" <> _
    | "gleamweekly.com"
    | "Gleam new mailing list"
    | "Gleam newsletter"
    | "Gleam Newsletter"
    | "Weekly email"
    | "Email newsletter"
    | "Email Newsletter"
    | "gleam newsletter"
    | "mailing list"
    | "Newsletter"
    | "Email"
    | "newsletter" -> ["Gleam Weekly"]

    "Elixir forum" -> ["Elixir Forum"]

    "linkedin" | "Linkedin" -> ["LinkedIn"]

    "Lobsters" | "lobsters" | "Lobste.rs" | "Lobster.rs" -> ["lobste.rs"]

    "Mastodon" | "Lemmy" | "Mastadon" -> ["The Fediverse"]

    "Discord Server"
    | "Discord server"
    | "The gleam discord" <> _
    | "Discord #sharing"
    | "Discord Gleam server"
    | "Discord Serevr"
    | "Gleam Discord"
    | "Gleam discord"
    | "gleam discord" <> _
    | "discord" -> ["The Gleam Discord Server"]

    "Gleam subreddit"
    | "reddit.com/r/gleamlang"
    | "reddit.com/r/elixir"
    | "Reddit"
    | "reddit.com" -> ["reddit"]

    "Reddit and Discord" -> ["reddit", "The Gleam Discord Server"]
    "discord and gleam weekly" -> ["Gleam Weekly", "The Gleam Discord Server"]

    "twitter"
    | "x"
    | "X"
    | "X (formerly Twitter)"
    | "Twitter @gleamlang"
    | "Twitter @louispilfold"
    | "Louis' twitter" <> _
    | "louis on twitter" -> ["Twitter"]

    "Hackernews" | "HN" | "hackernews" | "hacker news" -> ["Hacker News"]

    "Github" | "github" | "github repo" | "Repo's changelog" -> ["GitHub"]

    "https://kirakira.keii.dev" <> _ | "Kirakira" | "Kirakira :)" -> [
      "Kirakira",
    ]

    "BlueSky" | "Bsky" | "Hopefullly Bluesky soon?" -> ["Bluesky"]

    "Tildes" | "-" | "I'm the news" | "M" | "mostly" -> []

    "Daily.dev" -> ["daily.dev"]

    "Erlang Forums" | "ErlangForums" | "Niche Blogs" | "different rss feeds" -> [
      "Other websites",
    ]

    "Girlfriend"
    | "hayleigh thompson"
    | "Talking to Hayleigh"
    | "Guy from work wont stop talking about it" -> ["Word of mouth"]

    "Team members and conference talks" -> ["Word of mouth", "Conferences"]

    source -> [source]
  }
}

fn normalise_multi_field(
  response: Dict(String, String),
  field_name: String,
  normaliser: fn(String) -> List(String),
) -> Dict(String, String) {
  use answers <- normalise_field(response, field_name)
  answers
  |> string.split(",")
  |> list.flat_map(fn(os) { string.trim(os) |> normaliser })
  |> set.from_list
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
}

fn normalise_os(
  response: Dict(String, String),
  field_name: String,
) -> Dict(String, String) {
  use answers <- normalise_field(response, field_name)
  answers
  |> string.split(",")
  |> list.flat_map(fn(os) {
    case string.trim(os) {
      "GraalVM" | "Tauri" | "Wasmer" | ".NET" | "JVM" -> []

      "Illumos (OmniOS)" <> _ -> ["Illumos"]
      "ChromeOS" <> _ -> ["ChromeOS"]

      "Bare metal embedded" -> ["Embedded"]

      "WSL" -> ["Windows", "Linux"]

      "Fastly Compute"
      | "Containerised Linux in Kubernetes"
      | "AWS Lambda"
      | "Rhino"
      | "docker containers"
      | "Cloudflare Workers"
      | "Vercel" <> _
      | "void linux" -> ["Linux"]

      os -> [os]
    }
  })
  |> set.from_list
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
}

fn normalise_country(response: Dict(String, String)) -> Dict(String, String) {
  use country <- normalise_field(response, "country")
  case string.trim(country) {
    "Brasil" -> "Brazil"

    "Czech Republic" | "Czech republic" -> "Czechia"

    "spain" -> "Spain"
    "Russia" -> "The Russian Federation"
    "germany" -> "Germany"
    "japan" -> "Japan"
    "nigeria" -> "Nigeria"
    "france" -> "France"
    "belgium" -> "Belgium"
    "brazil" -> "Brazil"
    "denmark" -> "Denmark"
    "indonesia" -> "Indonesia"
    "nethrlands" -> "The Netherlands"
    "Vietnam" -> "Viet Nam"

    "The United Kingdom" <> _
    | "United Kingdom"
    | "UK"
    | "England"
    | "Scotland"
    | "Engerland innit bruv" -> "The United Kingdom"

    "United States of America"
    | "United States"
    | "united states"
    | "Usa"
    | "US"
    | "USA"
    | "The United States of America" <> _ -> "The United States of America"

    country -> country
  }
}

fn get_all_for_field(responses, field_name) {
  list.fold(responses, set.new(), fn(values, response) {
    case dict.get(response, field_name) {
      Ok(value) -> value |> string.split(",") |> list.fold(values, set.insert)
      _ -> values
    }
  })
  |> set.to_list
  |> list.sort(string.compare)
}

fn write_response_summaries(responses: List(Dict(String, String))) -> Nil {
  list.each(responses, fn(data) {
    let out =
      data
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> list.filter(fn(pair) {
        !list.contains(
          [
            "organisation-name", "organisation-size", "other-languages",
            "production-os", "professional-experience", "projects", "runtimes",
            "targets", "development-os", "gleam-experience",
            "gleam-in-production", "gleam-open-source", "gleam-user",
            "individual-sponsor", "job-role", "ip", "id", "inserted-at",
            "country", "news-sources", "organisation-sponsor",
          ],
          pair.0,
        )
      })
      |> list.map(fn(pair) { "## " <> pair.0 <> "\n\n" <> pair.1 <> "\n" })
      |> string.join("\n")
    case out {
      "" -> Nil
      _ -> {
        let assert Ok(id) = dict.get(data, "id")
        let filename = "tmp/responses/" <> id <> ".md"
        let assert Ok(_) = simplifile.write(filename, out)
        Nil
      }
    }
  })
}

fn parse(path: String, files: List(String)) -> List(Dict(String, String)) {
  list.sort(files, string.compare)
  |> list.map(fn(file) {
    let assert Ok(json) = simplifile.read(filepath.join(path, file))
    let assert Ok(data) =
      json.parse(json, decode.dict(decode.string, decode.string))
    data
  })
}
