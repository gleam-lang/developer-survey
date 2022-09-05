// IMPORTS ---------------------------------------------------------------------

import gleam/string
import lustre/cmd.{Cmd}

// TYPES -----------------------------------------------------------------------

///
pub type Route {
  Info
  Survey(SurveyRoute)
  Complete
  Unknown
}

///
pub type SurveyRoute {
  Demographics
  Languages
  Features
}

// CONSTRUCTORS ----------------------------------------------------------------

///
pub fn from_hash(hash: String) -> Route {
  case string.lowercase(hash) {
    "#" | "#/" | "#/info" -> Info
    "#/survey" | "#/survey/demographics" -> Survey(Demographics)
    "#/survey/languages" -> Survey(Languages)
    "#/survey/features" -> Survey(Features)
    "#/complete" -> Complete
    _ -> Unknown
  }
}

// CONVERSIONS -----------------------------------------------------------------

///
pub fn to_string(route: Route) -> String {
  case route {
    Info -> "#/info"
    Survey(Demographics) -> "#/survey/demographics"
    Survey(Languages) -> "#/survey/languages"
    Survey(Features) -> "#/survey/features"
    Complete -> "#/complete"
    Unknown -> "#/404"
  }
}

// COMMANDS --------------------------------------------------------------------

///
pub fn init(hash: String, action: fn(Route) -> action) -> #(Route, Cmd(action)) {
  #(
    from_hash(hash),
    cmd.from(fn(dispatch) {
      on_hash_change(fn(hash) {
        hash
        |> from_hash
        |> action
        |> dispatch
      })
    }),
  )
}

///
pub fn push(route: Route) -> Nil {
  route
  |> to_string
  |> change_hash
}

// EXTERNALS -------------------------------------------------------------------

///
external fn on_hash_change(fn(String) -> any) -> Nil =
  "ffi/window.mjs" "on_hash_change"

///
external fn change_hash(String) -> Nil =
  "ffi/window.mjs" "change_hash"
