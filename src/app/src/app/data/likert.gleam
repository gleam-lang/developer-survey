// IMPORTS ---------------------------------------------------------------------

import gleam/float
import gleam/int
import gleam/list
import gleam/set.{Set}
import lustre/attribute
import lustre/element.{Element}

// TYPES -----------------------------------------------------------------------

///
pub opaque type Likert {
  Likert(
    title: String,
    description: String,
    statements: List(Statement),
    count: Int,
  )
}

///
pub opaque type Rating {
  StronglyDisagree
  Disagree
  SomewhatDisagree
  Neutral
  SomewhatAgree
  Agree
  StronglyAgree
}

///
type Statement =
  #(String, Rating)

// CONSTRUCTORS ----------------------------------------------------------------

/// A three-point Likert scale with the given title and description. Prompts can
/// be rated as `Disagree`, `Neutral`, or `Agree`.
pub fn three_point(
  title: String,
  description: String,
  prompts: Set(String),
) -> Likert {
  Likert(title, description, shuffle_statements(prompts), 3)
}

/// A five-point Likert scale with the given title and description. Prompts can
/// be rated as `Strongly Disagree`, `Disagree`, `Neutral`, `Agree`, or 
/// `Strongly Agree`.
pub fn five_point(
  title: String,
  description: String,
  prompts: Set(String),
) -> Likert {
  Likert(title, description, shuffle_statements(prompts), 5)
}

/// A seven-point Likert scale with the given title and description. Prompts can
/// be rated as `Strongly Disagree`, `Disagree`, `Somewhat Disagree`, `Neutral`,
/// `Somewhat Agree`, `Agree`, or `Strongly Agree`.
pub fn seven_point(
  title: String,
  description: String,
  prompts: Set(String),
) -> Likert {
  Likert(title, description, shuffle_statements(prompts), 7)
}

// MANIPULATIONS ---------------------------------------------------------------

/// 
pub fn update(likert: Likert, prompt: String, rating: Rating) -> Likert {
  Likert(
    ..likert,
    statements: rate_statement(likert.statements, prompt, rating),
  )
}

// CONVERSIONS -----------------------------------------------------------------

///
pub fn render(
  likert: Likert,
  on_rate: fn(String, Rating) -> action,
) -> Element(action) {
  element.section(
    [attribute.attribute("data-likert", int.to_string(likert.count))],
    [],
  )
}

fn render_statement(
  statement: Statement,
  on_rate: fn(String, Rating) -> action,
) -> Element(action) {
  todo
}

fn render_labels(count: Int) -> Element(action) {
  // Could this be a custom type that actually limits the possibility to three,
  // five, or seven? Absolutely. 
  assert True = count == 3 || count == 5 || count == 7

  let ratings = case count {
    3 -> [Disagree, Neutral, Agree]
    5 -> [StronglyDisagree, Disagree, Neutral, Agree, StronglyAgree]
    7 -> [
      StronglyDisagree,
      Disagree,
      SomewhatDisagree,
      Neutral,
      SomewhatAgree,
      Agree,
      StronglyAgree,
    ]
  }

  todo
}

fn render_label(rating: Rating) -> Element(action) {
  element.span([], [element.text(rating_to_label(rating))])
}

fn rating_to_label(rating: Rating) -> String {
  case rating {
    StronglyDisagree -> "Strongly Disagree"
    Disagree -> "Disagree"
    SomewhatDisagree -> "Somewhat Disagree"
    Neutral -> "Neutral"
    SomewhatAgree -> "Somewhat Agree"
    Agree -> "Agree"
    StronglyAgree -> "Strongly Agree"
  }
}

// UTILS -----------------------------------------------------------------------

/// Why are we shuffling the statements? It's good practice to present Likert
/// statements in a random order to avoid bias and priming – the order in which
/// statements are presented can have a real effect on how people might respond.
///
fn shuffle_statements(prompts: Set(String)) -> List(Statement) {
  prompts
  // Prompts are passed in as a `Set` to guarantee there are no duplicates, but
  // we don't really need it to be one after a `Likert` is constructed – lists 
  // are fine.
  |> set.to_list
  // To shuffle the elements first we'll attach a random number to each
  // statement.
  |> list.map(fn(stmt) { #(stmt, random_float(0.0, 1.0)) })
  // Then we'll sort the list by that random number.
  |> list.sort(fn(a, b) { float.compare(a.1, b.1) })
  // The Likert statements should all have a neutral rating to start off with
  // so we'll just take the original statement string, drop the random number
  // we generated, and replace it with a `Neutral` rating.
  |> list.map(fn(stmt) { #(stmt.0, Neutral) })
}

/// Mapping over a list just to update a single element isn't particularly
/// clever or efficient, but in practice the number of statements we'll be
/// dealing with in any one Likert scale is small enough that it doesn't really
/// matter.
///
/// ❗️ This function assumes that the provided prompt already exists in the list
/// of statements. It does *not* insert a new statement if it doesn't – Likert
/// scales are fixed at the time of creation.
///
fn rate_statement(
  statements: List(Statement),
  prompt: String,
  rating: Rating,
) -> List(Statement) {
  statements
  |> list.map(fn(stmt) {
    case stmt.0 == prompt {
      True -> #(prompt, rating)
      False -> stmt
    }
  })
}

// EXTERNALS -------------------------------------------------------------------

external fn random_float(min: Float, max: Float) -> Float =
  "ffi/random.mjs" "float"
