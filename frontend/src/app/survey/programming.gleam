// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/loop.{Action, UpdateProfessionalExperience}
import app/ui/section
import app/ui/inputs
import app/ui/text
import app/ui/tidbit
import app/util/render
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{Element}

const programming_languages = [
  "C", "C++", "C#", "Elixir", "Elm", "Erlang", "Go", "Haskell", "Java",
  "JavaScript", "Julia", "Kotlin", "Lisp", "OCaml", "PHP", "Python", "Ruby",
  "Rust", "Scala", "Swift", "TypeScript",
]

const timeframes = [
  NA,
  LessThan("1 year"),
  Between("1", "2 years"),
  Between("2", "5 years"),
  Between("5", "10 years"),
  MoreThan("10 years"),
]

const company_sizes = [
  Between("1", "10 employees"),
  Between("11", "50 employees"),
  Between("50", "100 employees"),
  MoreThan("100 employees"),
]

// RENDER ----------------------------------------------------------------------

pub fn render(professional_experience: Range) -> Element(Action) {
  section.render([
    section.title(
      "Section 1",
      "You as a programmer",
      Some("programming"),
      element.h2,
    ),
    text.render(
      " We'd like to know a bit about your background and programming
        experience. Maybe Gleam developers are all embedded engineers working
        with C? Maybe they're all web developers using Elm? We don't know, but
        we'd like to find out!
      ",
    ),
    // Programming experience --------------------------------------------------
    text.render_question("How long have you been programming?"),
    text.render("Either personally or professionally, whatever's longest!"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        inputs.select(
          "programming_experience",
          [],
          list.map(timeframes, range.to_string(_, None)),
        ),
      ],
    ),
    // Professional experience -------------------------------------------------
    text.render_question("How long have you been programming professionally?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        inputs.select(
          "professional_programming_experience",
          [
            inputs.on_change(fn(value) {
              UpdateProfessionalExperience(range.from_string(value))
            }),
          ],
          list.map(timeframes, range.to_string(_, None)),
        ),
      ],
    ),
    // Current role ------------------------------------------------------------
    render.when(
      professional_experience != NA,
      fn() {
        element.fragment([
          text.render_question("What's your current role?"),
          text.render(
            "If you're not working right now, think back to your previous or most recent role.",
          ),
          tidbit.render(
            " Roles and titles are so varied that we thought it would
              be easier to leave this as free-form and then aggregate the results
              manually.",
          ),
          inputs.text("role"),
        ])
      },
    ),
    // Company size ------------------------------------------------------------
    render.when(
      professional_experience != NA,
      fn() {
        element.fragment([
          text.render_question("How many people work at your company?"),
          text.render(
            "If you're not working right now, think back to your previous company.",
          ),
          element.div(
            [attribute.class("max-w-xl mx-auto")],
            [
              inputs.select(
                "company_size",
                [],
                list.map(company_sizes, range.to_string(_, None)),
              ),
            ],
          ),
        ])
      },
    ),
    // Languages used ------------------------------------------------------------
    text.render_question("Which of the following languages do you use?"),
    text.render("Both personally and at work. Select all that apply."),
    inputs.multiselect("languages_used", programming_languages),
    text.render_question("Any other languages?"),
    inputs.text("other_langs"),
  ])
}
