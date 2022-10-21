// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan}
import app/data/loop.{Action}
import app/ui/section
import app/ui/inputs
import app/ui/text
import app/util/countries
import gleam/list
import gleam/option.{None, Some}
import lustre/element.{Element}

const ages = [
  LessThan("18 years old"),
  Between("19", "24 years old"),
  Between("25", "34 years old"),
  Between("35", "44 years old"),
  Between("45", "54 years old"),
  Between("55", "64 years old"),
  MoreThan("65 years old"),
]

const genders = ["Female", "Male", "Non-binary"]

const sexual_orientations = [
  "Bisexual or Pansexual", "Gay or Lesbian", "Straight or Heterosexual", "Queer",
]

// RENDER ----------------------------------------------------------------------

pub fn render() -> Element(Action) {
  section.render([
    section.title("Section 3", "About you", Some("about"), element.h2),
    text.render(
      " This section is about who you are.
        Gleam is for everybody and all kinds of people are enthusiastically
        welcomed in our community. If you don't want to answer any of these
        questions just skip to the next one.
      ",
    ),
    // Country -----------------------------------------------------------------
    text.render_question("What country are you based in?"),
    inputs.select("country", [], countries.names_and_flags()),
    // Age ---------------------------------------------------------------------
    text.render_question("What is your age?"),
    inputs.select("age", [], list.map(ages, range.to_string(_, None))),
    // Gender ------------------------------------------------------------------
    text.render_question("What is your gender?"),
    inputs.select_with_other("gender", [], genders),
    // Transgender -------------------------------------------------------------
    text.render_question("Are you transgender?"),
    inputs.select("transgender", [], ["", "Yes", "No", "Maybe"]),
    // Sexual Orientation ------------------------------------------------------
    text.render_question("What is your sexual orientation?"),
    inputs.select_with_other("sexual-orientation", [], sexual_orientations),
  ])
}
