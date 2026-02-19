import argv
import filepath
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/function
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile
import storail
import survey

const field_anything_else = "anything-else"

const field_country = "country"

const field_development_os = "development-os"

const field_email = "email"

const field_gleam_experience = "gleam-experience"

const field_gleam_in_production = "gleam-in-production"

const field_gleam_open_source = "gleam-open-source"

const field_gleam_user = "gleam-user"

const field_improvements = "improvements"

const field_individual_sponsor = "individual-sponsor"

const field_inserted_at = "inserted-at"

const field_id = "id"

const field_ip = "ip"

const field_job_role = "job-role"

const field_learn_about_gleam = "learn-about-gleam"

const field_likes = "likes"

const field_news_sources = "news-sources"

const field_organisation_name = "organisation-name"

const field_organisation_size = "organisation-size"

const field_organisation_sponsor = "organisation-sponsor"

const field_other_contribution = "other-contribution"

const field_other_languages = "other-languages"

const field_production_os = "production-os"

const field_professional_experience = "professional-experience"

const field_projects = "projects"

const field_runtimes = "runtimes"

const field_sponsor_motivation = "sponsor-motivation"

const field_targets = "targets"

pub const summary = "tmp/summary.md"

pub fn main() {
  let assert [path] = argv.load().arguments
  let assert Ok(_) = simplifile.delete_all(["tmp/responses"])
  let assert Ok(_) = simplifile.create_directory_all("tmp/responses")
  let assert Ok(_) = simplifile.write(summary, "# Summary\n\n")
  let collection = survey.data_collection(path)
  let assert Ok(items) = storail.list(collection, [])

  let raw_data =
    list.map(items, fn(name) {
      let assert Ok(entry) = collection |> storail.key(name) |> storail.read()
      #(name, dict.from_list(entry))
    })
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(pair.second)

  // Remove spam
  let data = list.filter(raw_data, fn(entry) { !is_spam(entry) })
  echo list.length(data) as "without spam"

  // Remove empty submissions
  let data = list.filter(data, fn(entry) { dict.size(entry) > 3 })
  echo list.length(data) as "without empty"

  // Remove duplicates. These are those that have the same answers, and only
  // the auto-inserted fields have changed.
  let data =
    list.group(data, fn(entry) {
      entry |> dict.delete(field_id) |> dict.delete(field_inserted_at)
    })
    |> dict.values
    |> list.filter_map(list.first)

  echo list.length(data) as "without duplicates"

  let data =
    data
    |> list.map(normalise_country)
    |> list.map(normalise_os(_, field_development_os))
    |> list.map(normalise_os(_, field_production_os))
    |> list.map(normalise_news)
    |> list.map(normalise_role)
    |> list.map(normalise_other_languages)

  // io.println(get_all_for_field(data, field_ip))

  let assert Ok(_) =
    simplifile.write(
      summary,
      "## Responses\n\n" <> int.to_string(list.length(data)) <> "\n\n",
    )
  //
  // add_counts(data, "Gleam user", "gleam-user", yes)
  // add_counts(data, "Gleam in production", "gleam-in-production", yes)
  //
  // add_counts(data, "News sources", "news-sources", yes)
  //
  // add_counts(data, "Country", "country", yes)
  // add_counts(data, "Country (Prod users)", "country", in_prod)
  //
  // add_counts(data, "Dev OS", "development-os", yes)
  // add_counts(data, "Dev OS (Prod users)", "development-os", in_prod)
  //
  // add_counts(data, "Prod OS", "production-os", yes)
  // add_counts(data, "Prod OS (Prod users)", "production-os", in_prod)
  //
  // add_counts(data, "Prod OS", "production-os", yes)
  // add_counts(data, "Prod OS (Prod users)", "production-os", in_prod)
  //
  // add_counts(data, "Career", "professional-experience", yes)
  // add_counts(data, "Career (Prod users)", "professional-experience", in_prod)
  //
  // add_counts(data, "Years of Gleam", "gleam-experience", yes)
  // add_counts(data, "Years of Gleam (Prod users)", "gleam-experience", in_prod)
  //
  // add_counts(data, "Targets used", "targets", yes)
  // add_counts(data, "Targets used (Prod users)", "targets", in_prod)
  //
  // add_counts(data, "Runtimes used", "runtimes", yes)
  // add_counts(data, "Runtimes used (Prod users)", "runtimes", in_prod)
  //
  // add_counts(data, "Project types", "projects", yes)
  // add_counts(data, "Project types (Prod users)", "projects", in_prod)
  //
  // add_counts(data, "Does Gleam OSS", "gleam-open-source", yes)
  // add_counts(data, "Does Gleam OSS (Prod user)", "gleam-open-source", in_prod)
  //
  // add_counts(data, "Sponsor", "individual-sponsor", yes)
  // add_counts(data, "Sponsor (Prod user)", "individual-sponsor", in_prod)
  // add_counts(data, "Org sponsor", "organisation-sponsor", yes)
  // add_counts(data, "Org sponsor (Prod user)", "organisation-sponsor", in_prod)
  //
  // add_counts(data, "Org size", "organisation-size", yes)
  // add_counts(data, "Org size (Prod user)", "organisation-size", in_prod)
  //
  // add_counts(data, "Job", "job-role", yes)
  //
  // add_counts(data, "Other languages", "other-languages", yes)
  // add_counts(data, "Other languages (Prod users)", "other-languages", in_prod)
  //
  write_response_summaries(data)
  //
  // let assert Ok(summary) = simplifile.read(summary)
  // io.print(summary)
  //
  //
  Nil
}

fn is_spam(entry: Dict(String, List(String))) -> Bool {
  entry
  |> dict.values
  |> list.flatten
  |> list.any(string.contains(_, "yandex.com/poll/"))
}

fn normalise_other_languages(dict) {
  use language <- normalise_field(dict, field_other_languages)
  use language <- list.flat_map(string.split(language, ", "))
  let language = language |> string.replace("(learning)", "") |> string.trim

  case language {
    "Many more..."
    | "-"
    | "a million"
    | "Tcl"
    | "Terraform"
    | "HTML"
    | "Html"
    | "html/css"
    | "OpenTofu/HCL"
    | "HCL"
    | "German"
    | "Gleam"
    | "French"
    | "English"
    | "english"
    | "CSS"
    | "CAP CDS"
    | "Lots"
    | "SCSS"
    | "Russian"
    | "Swedish"
    | "Yaml" -> []

    "C# F# Typescript" -> ["C#", "F#", "TypeScript"]
    "Elixir Erlang Ruby Zig Swift" -> [
      "Elixir",
      "Erlang",
      "Ruby",
      "Zig",
      "Swift",
    ]
    "go rust swift" -> ["Go", "Rust", "Swift"]
    "Scala" | "scala" -> ["Scala"]

    "Nix" | "nix" -> ["Nix"]

    "Lua" | "lua" -> ["Lua"]

    "MATLAB" | "Matlab" -> ["Matlab"]

    "OCaml" | "Ocaml" | "ocaml" -> ["OCaml"]

    "GDScript" | "Gdscript" | "GDscript" -> ["GDScript"]

    "CoffeScript" -> ["CoffeeScript"]

    "Swift" | "swift" -> ["Swift"]
    "ReScript" | "Rescript" -> ["ReScript"]

    "Odin" | "odin for personal projects" -> ["Odin"]

    "Abap" -> ["ABAP"]
    "mainly java" | "To many to list but mainly: Java" | "and Java" -> ["Java"]
    "Assemblyscript" -> ["AssemblyScript"]
    "Bash" | "BASH" | "Shell / Bash" | "bash" -> ["Bash"]
    "c" -> ["C"]
    ".net" | "csharp" | "c#" -> ["C#"]
    "c++" -> ["C++"]
    "clojure" -> ["Clojure"]
    "Common lisp" -> ["Common Lisp"]
    "dart" -> ["Dart"]
    "delphi" -> ["Delphi"]
    "Eelang" -> ["Erlang"]
    "Elixir Javascript Typescript Python Ruby" -> [
      "Elixir", "Javascript", "Typescript", "Python", "Ruby",
    ]
    "elixir" -> ["Elixir"]
    "elm" -> ["Elm"]
    "erlang" -> ["Erlang"]
    "f#" -> ["F#"]
    "Go (unfortunately)" -> ["Go"]
    "go php js" -> ["Go", "PHP", "JavaScript"]
    "go" -> ["Go"]
    "Golang" -> ["Go"]
    "I also know the fundamentals of C and Elixir" -> ["C", "Elixir"]
    "java" -> ["Java"]

    "nodejs"
    | "JavaScript"
    | "Javascript SMTH ELSE I THINH"
    | "JavaScript(TS)"
    | "JS (trying to avoid it though)"
    | "Javascript"
    | "Js"
    | "js"
    | "JS"
    | "javascript" -> ["JavaScript"]
    "JS and PHP" -> ["JavaScript", "PHP"]
    "JS/TS" | "js/ts" | "JavaScript/TypeScript" -> ["JavaScript", "TypeScript"]
    "kotlin" -> ["Kotlin"]
    "Lean 4" -> ["Lean"]
    "PHP" | "Php" | "php" -> ["PHP"]
    "Nu Shell" | "nushell" -> ["Nushell"]
    "SQL" | "sql" | "postgres" | "Sql" -> ["SQL"]
    "Powershell" | "Poweshell" | "PowerShell" -> ["PowerShell"]
    "prolog" -> ["Prolog"]
    "and python" | "Python...." | "python" -> ["Python"]
    "rescript" -> ["ReScript"]
    "Ruby (on occasion)" | "a bit of ruby" | "ruby" -> ["Ruby"]
    "rust" -> ["Rust"]
    "shell" | "Shell" -> ["POSIX Shell"]
    "SScala" -> ["Scala"]
    "TS" | "ts" | "TypScript" | "Typscript" | "Typescript" | "typescript" -> [
      "TypeScript",
    ]
    "V (go)" -> ["V"]
    "Zig" | "zig" -> ["Zig"]

    language -> [language]
  }
}

fn normalise_role(dict) {
  use role <- normalise_field(dict, field_job_role)
  case role {
    "Design Engineer" | "Maker" -> ["Hardware Developer"]

    "Engineering Manager" | "Software Manager" | "EM" -> [
      "Software Development Manager",
    ]

    "System Analyst" | "Backend Analyst" | "Analyst" -> ["Analyst"]

    "Consultant"
    | "Devops Consultant"
    | "Lead Developer; independent consultant"
    | "Consulting Engineer"
    | "Software Engineering Consultant"
    | "Integration Consultant / Java Developer"
    | "Consultant/Senior Engineer"
    | "Software developer and consultant"
    | "Technical consultant" -> ["Consultant"]

    "Translator"
    | "Developer Advocate"
    | "Head of Finance"
    | "Head of department"
    | "Creative director" -> ["Other"]

    "Administrator System"
    | "Devops Engineer"
    | "DevOps Engineer"
    | "DevOps"
    | "DevSecOps Engineer"
    | "Site reliability engenier"
    | "Senior Site Reliability Engineer"
    | "SRE"
    | "Systems librarian"
    | "Programmer/Sysadmin" -> ["System administrator"]

    "Machine Learning Engineer" | "Machine learning engineer" -> [
      "Machine Learning Engineer",
    ]

    "Data Scientist" | "Data Analyst / Statistician" -> ["Data Scientist"]

    "Principal Engineer"
    | "Principal Software Engineer"
    | "Principal Technical Lead" -> ["Principal Software Developer"]

    "Founding Engineer"
    | "VP Data & Analytics"
    | "Head of Engineering " <> _
    | "Head of Engineering"
    | "Director of Engineering"
    | "Head of IT operations (sysadmin/developer)"
    | "Head of Software Devlopement"
    | "Head of Software"
    | "Director of Enterprise Applications"
    | "Technical Director" -> ["Head of Development"]

    "QA" | "Software QA Engineer" | "Quality Assurance Architect" -> ["QA"]

    "President"
    | "Director"
    | "COO"
    | "Managing Director"
    | "Founder"
    | "Start-up founder"
    | "CEO"
    | "Company Director"
    | "CISO"
    | "Bootstrapper" -> ["Non-technical C-level executive"]

    "Staff Engineer"
    | "Staff Software Engineer"
    | "Staff software engineer"
    | "Staff Infrastructure Engineer"
    | "Staff Frontend Engineer" -> ["Staff Software Developer"]

    "Designer"
    | "UX Designer"
    | "Web designer"
    | "UI Artist"
    | "Digital Artist"
    | "Frontend Developer and UX Designer" -> ["Designer"]

    "Principal Architect"
    | "Solutions Architect / SRE"
    | "Cloud Architect"
    | "Principal Archtiect"
    | "System Architect"
    | "Archtect and Software engineer"
    | "Software Architec"
    | "Software Architect"
    | "Software architect"
    | "Solution Architect"
    | "Soware Architect"
    | "Cloud Engineer/Architect" -> ["Software Architect"]

    "Vice President; Engineering"
    | "ceo/engineering lead"
    | "CTO"
    | "cto"
    | "Cto"
    | "CTO/Chief Architect"
    | "I guess officially CTO" <> _ -> ["CTO"]

    "Research Software Engineer"
    | "Research Developer"
    | "Scientific Researcher"
    | "Researcher"
    | "Scientist"
    | "Senior scientist" -> ["Researcher"]

    "Student"
    | "PhD student"
    | "None (school)"
    | "PhD Student / Research Assistant"
    | "PhD Student"
    | "Intern"
    | "Postdoc"
    | "High School Student"
    | "IT-student"
    | "PhD Student (Computational neuroscience)"
    | "Software Development Student"
    | "Student; " <> _
    | "Student (KU Leuven)"
    | "University student"
    | "student" -> ["Student"]

    "Junior Instructor"
    | "Lecturer"
    | "Assistant Professor"
    | "Teacher"
    | "Teaching Assistant"
    | "Learning Coach" -> ["Educator"]

    "Lead Backend Engineer"
    | "Team Tech Lead"
    | "SE Team Lead"
    | "lead dev"
    | "Software Team Lead"
    | "Lead engineer"
    | "Backend team lead"
    | "R&D Lead"
    | "Lead dev"
    | "Lead Developer"
    | "Lead Engineer"
    | "Lead Fullstack Developer"
    | "Lead software engineer"
    | "Senior dev + team lead"
    | "Web team lead"
    | "Tech Lead"
    | "Tech lead"
    | "tech lead" -> ["Tech Lead"]

    "code monkey"
    | "Infrastructure engineer"
    | "iOS developer"
    | "R&D Engineer"
    | "Security engineer"
    | "Sr Software Engineer"
    | "Sr. Software Engineer (Backend)"
    | "tools developer"
    | "SEO Programmer"
    | "Senior Data Engeneer"
    | "Data engineer"
    | "Intermediate Software Developer"
    | "Junior Software Engineer"
    | "Open Source Engineer"
    | "Platform Engineer"
    | "Senior Developer"
    | "Senior Engineer"
    | "Senior Software Engineer"
    | "senior software engineer"
    | "Senior Staff Software Engineer"
    | "Senior SWE"
    | "Computer Programmer"
    | "Self Employed Software Contractor"
    | "Contractor"
    | "Contractor/Senior Developer"
    | "freelance"
    | "Software Engineer " <> _
    | "Software Engineer"
    | "Freelancer"
    | "System Engineer"
    | "Systems Software Engineer"
    | "Developer / Community specialist"
    | "Devoloper and System Administrator"
    | "Developer FullStack"
    | "Full-stack developer"
    | "Full stack"
    | "Full Stack Developer"
    | "Full Stack Dev"
    | "FullStack Software Engineer"
    | "senior full stack developer"
    | "Full Stack Developper"
    | "Senior Full Stack Developer"
    | "Developer Relations"
    | "Developer"
    | "developer"
    | "Development"
    | "Developper; not lead but kinda lead in my projects."
    | "Front-end developer"
    | "Frontend  Engineer"
    | "Frontend Developer"
    | "Frontend engineer"
    | "Frontend Engineer"
    | "full stack dev"
    | "Full stack developer"
    | "Full Stack Software Developer"
    | "Full Stack Web Developer"
    | "Full-Stack developer"
    | "Full-stack Software Developer"
    | "Full-stack"
    | "Fullstack developer"
    | "Fullstack Developer"
    | "fullstack developer"
    | "Fullstack Engineer"
    | "fullstack engineer"
    | "Fullstack Software Developer"
    | "Fullstack web dev"
    | "Fullstack Web developer"
    | "Fullstack"
    | "Web Developer"
    | "Web Devevloper"
    | "web dev"
    | "Software Developer"
    | "Software developer"
    | "Software engineer"
    | "software engineer"
    | "Software Engineer; UX/UI Designer"
    | "Web Backend Developer"
    | "Back-end Developer"
    | "Backend Dev"
    | "Backend developer"
    | "Backend Developer"
    | "backend developer"
    | "Backend Engineer"
    | "Backend engineer"
    | "SWE"
    | "Solo game dev"
    | "IoT Software Engineer"
    | "Compiler Developer"
    | "Senior Software Developer"
    | "Founding software Engineer"
    | "télécoms software engineer"
    | "Erlang dev"
    | "Backend dev"
    | "Señor Software Engineer"
    | "Web developer (looking for a job)"
    | "Embedded Linux Software Engineer"
    | "Gleam Core Team Member"
    | "Dev"
    | "backend"
    | "Front end engineer"
    | "Embedded software engineer"
    | "Elixir Developer"
    | "Senior software engineer"
    | "Data Engineer"
    | "Freelance"
    | "Engineer"
    | "Programmer"
    | "Scrum Master / Kernel maintainer" -> ["Software Developer"]

    "Programming for fun for moment"
    | "Professionally jobless"
    | "Personal Guyy"
    | "n/a"
    | "-"
    | "Unemployed" <> _
    | "unemployed" <> _
    | "jobless"
    | "retired software architect"
    | "Retired"
    | "Self Employed"
    | "N.A."
    | "N/A"
    | "None;" <> _
    | "None"
    | "retired"
    | "none"
    | "Funemployed SW engineer"
    | "Hobbyist" -> []

    role -> [role]
  }
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
  response: Dict(String, List(String)),
  field_name: String,
  normalise: fn(String) -> List(String),
) -> Dict(String, List(String)) {
  case dict.get(response, field_name) {
    Ok(answer) -> {
      let answer =
        list.flat_map(answer, fn(entry) { entry |> string.trim |> normalise })
        |> list.unique
      case answer {
        [] -> dict.delete(response, field_name)
        answer -> dict.insert(response, field_name, answer)
      }
    }
    Error(_) -> response
  }
}

const news_twitter = "X née Twitter"

const news_discord = "The Gleam Discord Server"

fn normalise_news(
  response: Dict(String, List(String)),
) -> Dict(String, List(String)) {
  use source <- normalise_field(response, field_news_sources)
  case source {
    "RSS, AT protocol, email" -> ["gleam.run", "Bluesky", "Gleam Weekly"]

    "LinkedIn, YouTube, but I want to see news on X too" -> [
      "LinkedIn",
      "YouTube",
      news_twitter,
    ]

    "Discord and Gleam Weekly" -> [news_discord, "Gleam Weekly"]
    "Discord, Reddit, Bluesky" -> [news_discord, "reddit", "Bluesky"]
    "Twitter @gleamlang, youtube" -> [news_twitter, "YouTube"]
    "Reddit/Discord/guest podcast appearances" -> [
      "reddit",
      news_discord,
      "Podcasts",
    ]

    "Discord, packages.gleam.run" -> [news_discord, "gleam.run"]
    "Discord, YouTube" -> [news_discord, "YouTube"]
    "Reddit, Discord" -> ["reddit", news_discord]
    "The Gleam news section and Gleam Weekly" -> ["gleam.run", "Gleam Weekly"]
    "Gleam site, discord," -> ["gleam.run", news_discord]
    "bluesky, youtube, the blog" -> ["Bluesky", "YouTube", "gleam.run"]

    "Podcasts" | "Thinking Elixir Podcast" -> ["Podcasts"]

    "Jak's streams" | "twitch" -> ["Twitch"]

    "Not much?"
    | "I dont have a great source for this yet, tbh."
    | "nowhere"
    | "I don't." -> []

    "Site oficial"
    | "Release post"
    | "Release Notes"
    | "News page"
    | "Blog"
    | "rss"
    | "The Gleam Blog"
    | "Rss feed"
    | "gleam.run" <> _
    | "RSS Feed"
    | "The official website"
    | "the official website"
    | "here, I guess :)"
    | "Gleam web"
    | "Gleam RSS"
    | "I don't, but here on gleam.run I think..."
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
    | "YouTube"
    | "Louis’ Youtube"
    | "Various YouTubers, not Gleam specific"
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

    "subscribed to gleam official emails"
    | "The newsletter"
    | "Newsletters"
    | "Weekly newsletter"
    | "Gleam Weekly"
    | "gleam weekly"
    | "The gleam weekly newsletter"
    | "The Gleam Weekly" <> _
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

    "Elixirforum" | "Elixir forum" -> ["Elixir Forum"]

    "linkedin" | "Linkedin" -> ["LinkedIn"]

    "Social media (lobste.rs)"
    | "lobster"
    | "lobste.rs :D"
    | "Lobsters"
    | "lobsters"
    | "Lobste.rs"
    | "Lobster.rs" -> ["lobste.rs"]

    "mastodon"
    | "The Fediverse"
    | "Fediverse"
    | "Mastodon"
    | "Lemmy"
    | "Mastadon" -> ["The Fediverse"]

    "Discord Server"
    | "The Gleam Discord Server"
    | "Discord"
    | "Disccord"
    | "#announcements on discord"
    | "The Gleam Discord"
    | "Discord (it's terrible)"
    | "Gleam discord server"
    | "discord #core channel ;)"
    | "In discord"
    | "The Discord"
    | "Occasionally lurk in Discord"
    | "mostly discord"
    | "The Discord server"
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
    | "https://www.reddit.com/r/gleamlang/"
    | "Reddit.com"
    | "subreddit"
    | "reddit"
    | "The Gleam subreddit"
    | "The gleam subreddit"
    | "reddit.com/r/gleamlang"
    | "reddit.com/r/elixir"
    | "Reddit"
    | "reddit.com" -> ["reddit"]

    "Reddit and Discord" -> ["reddit", "The Gleam Discord Server"]
    "discord and gleam weekly" -> ["Gleam Weekly", "The Gleam Discord Server"]

    "twitter"
    | "X.com"
    | "Twitter"
    | "x"
    | "X"
    | "X (formerly Twitter)"
    | "Twitter @gleamlang"
    | "Twitter @louispilfold"
    | "Louis' twitter" <> _
    | "louis on twitter" -> ["X née Twitter"]

    "Hackernews" | "HN" | "hackernews" | "hacker news" -> ["Hacker News"]

    "Following Commit Log (only a few repos since its so splitered)"
    | "Github PRs"
    | "changelog"
    | "GitHub"
    | "Github"
    | "github"
    | "github repo"
    | "Repo's changelog" -> ["GitHub"]

    "https://kirakira.keii.dev" <> _ | "Kirakira" | "Kirakira :)" -> [
      "Kirakira",
    ]

    "Bluesky"
    | "bluesky"
    | "bsky"
    | "gleam's bluesky"
    | "BlueSky"
    | "Bsky"
    | "Hopefullly Bluesky soon?" -> ["Bluesky"]

    "Tildes" | "-" | "I'm the news" | "M" | "mostly" -> []

    "Daily.dev" -> ["daily.dev"]

    "Erlang Forums" | "ErlangForums" -> ["The Erlang Forums"]

    "forums"
    | "Sometimes I just google gleam"
    | "Devio"
    | "Niche Blogs"
    | "different rss feeds" -> [
      "Other websites",
    ]

    "Like last year, i get constant updates from my colleague. Our Slack dev channel is now manly him writing about how awesome gleam is."
    | "People just tell me"
    | "social media"
    | "Hayleigh"
    | "Girlfriend"
    | "hayleigh thompson"
    | "Talking to Hayleigh"
    | "Guy from work wont stop talking about it" -> ["Word of mouth"]

    "Team members and conference talks" -> ["Word of mouth", "Conferences"]

    source -> [source]
  }
}

fn normalise_os(
  response: Dict(String, List(String)),
  field_name: String,
) -> Dict(String, List(String)) {
  use answer <- normalise_field(response, field_name)
  case answer {
    "ClearScript" <> _
    | "Wasm(" <> _
    | "GraalVM"
    | "quick-js"
    | "webdriver"
    | "Electron apps"
    | "None"
    | "Tauri"
    | "Wasmer"
    | ".NET"
    | "JVM"
    | "The Browser " <> _ -> []

    "illumos, IBM i" -> ["Illumos", "IBM i"]

    "Illumos (OmniOS)" <> _ -> ["Illumos"]
    "ChromeOS" <> _ -> ["ChromeOS"]

    "Bare metal embedded" -> ["Embedded"]

    "FreeRTOS (for AtomVM)" -> ["FreeRTOS"]

    "WSL" -> ["Windows", "Linux"]

    "MacOS But With A Grain a salt like only for builidng IPA" -> ["macOS"]

    "Fastly Compute"
    | "NixOS"
    | "Raspberry Pi OS" <> _
    | "Containerised Linux in Kubernetes"
    | "AWS Lambda"
    | "Aws Lambdas"
    | "Rhino"
    | "docker containers"
    | "Cloudflare Workers"
    | "Vercel" <> _
    | "void linux" -> ["Linux"]

    os -> [os]
  }
}

fn normalise_country(
  response: Dict(String, List(String)),
) -> Dict(String, List(String)) {
  use country <- normalise_field(response, field_country)
  case country {
    "Brasil (BR)" | "Brasil" -> ["Brazil"]

    "Czech Republic" | "Czech republic" -> ["Czechia"]

    "spain" -> ["Spain"]
    "Russia" -> ["The Russian Federation"]
    "germany" -> ["Germany"]
    "japan" -> ["Japan"]
    "nigeria" -> ["Nigeria"]
    "france" -> ["France"]
    "belgium" -> ["Belgium"]
    "denmark" -> ["Denmark"]
    "indonesia" -> ["Indonesia"]
    "nethrlands" -> ["The Netherlands"]
    "Vietnam" -> ["Viet Nam"]

    "hong kong" -> ["Hong Kong"]
    "Hong Kong / Ireland" -> ["Ireland", "Hong Kong"]

    "France" | "France (île de la réunion)" -> ["France"]

    "Mexico" | "México" -> ["Mexico"]

    "Sweden" | "sweden" -> ["Sweden"]

    "Taiwan" | "Taiwan (NOT A PROVENCE OF CHINA!!!!!!!!!)" -> ["Taiwan"]

    "The Netherlands" | "the Netherlands" -> ["The Netherlands"]

    "brazil" -> ["Brazil"]

    "The United Kingdom" <> _
    | "United Kingdom"
    | "United kingdom"
    | "UK"
    | "uK"
    | "uk"
    | "England"
    | "Scotland"
    | "Engerland innit bruv" -> ["The United Kingdom"]

    "United States of America"
    | "United States"
    | "united states"
    | "usa"
    | "Usa"
    | "US"
    | "USA"
    | "The United States of America" <> _ -> ["The United States of America"]

    "Mars" | "mars" -> []

    country -> [country]
  }
}

fn get_all_for_field(
  responses: List(Dict(a, List(String))),
  field_name: a,
) -> String {
  list.flat_map(responses, fn(response) {
    dict.get(response, field_name) |> result.unwrap([])
  })
  |> list.group(function.identity)
  |> dict.map_values(fn(_, a) { list.length(a) })
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(b.0, a.0) })
  |> list.map(fn(row) { row.0 <> "\t" <> int.to_string(row.1) })
  |> string.join("\n")
}

fn write_response_summaries(responses: List(Dict(String, List(String)))) -> Nil {
  list.each(responses, fn(data) {
    let out =
      data
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> list.filter(fn(pair) {
        !list.contains(
          [
            "country",
            "development-os",
            "email",
            "gleam-experience",
            "gleam-in-production",
            "gleam-open-source",
            "gleam-user",
            "id",
            "individual-sponsor",
            "inserted-at",
            "ip",
            "job-role",
            "learn-about-gleam",
            "likes",
            "news-sources",
            "organisation-name",
            "organisation-size",
            "organisation-sponsor",
            "other-contribution",
            "other-languages",
            "production-os",
            "professional-experience",
            "projects",
            "runtimes",
            "sponsor-motivation",
            "targets",

            //
            "other-contribution,",
          ],
          pair.0,
        )
      })
      |> list.map(fn(pair) {
        "## " <> pair.0 <> "\n\n" <> string.join(pair.1, "\n\n") <> "\n"
      })
      |> string.join("\n")

    case out {
      "" -> Nil
      _ -> {
        let assert Ok(id) = dict.get(data, "id")
        let filename = "tmp/responses/" <> string.concat(id) <> ".md"
        let assert Ok(_) = simplifile.write(filename, out)
        Nil
      }
    }
  })
}
