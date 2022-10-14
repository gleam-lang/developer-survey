// IMPORTS ---------------------------------------------------------------------

import gleam/string
import gleam/option.{Option}

// TYPES -----------------------------------------------------------------------

/// This is a kinda lazy type. We want to be able to express things like:
///
///     LessThan("6 months")
///     Between("1", "2 years")
///
/// We could have a more robust type but this is probably fine.
///
pub type Range {
  NA
  LessThan(String)
  Between(String, String)
  MoreThan(String)
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn from_string(str: String) -> Range {
  // Oh hey, I found a use for that string pattern matching proposal. It'd be
  // well nice to just strip out the `less than ` and `more than ` bits.
  let is_lessthan = string.starts_with(str, "less than ")
  let is_morethan = string.starts_with(str, "more than ")
  case str {
    _ if is_lessthan ->
      str
      |> string.replace("less than ", "")
      |> LessThan
    _ if is_morethan ->
      str
      |> string.replace("more than ", "")
      |> MoreThan
    _ ->
      case string.split(str, " to ") {
        [min, max] -> Between(min, max)
        _ -> NA
      }
  }
}

// CONVERSIONS -----------------------------------------------------------------

pub fn to_string(range: Range, na: Option(String)) -> String {
  case range {
    NA -> option.unwrap(na, "N/A")
    LessThan(label) -> string.concat(["less than ", label])
    Between(min, max) -> string.concat([min, " to ", max])
    MoreThan(label) -> string.concat(["more than ", label])
  }
}
