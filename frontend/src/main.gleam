// IMPORTS ---------------------------------------------------------------------

import app/data/loop.{
  Action, Noop, State, UpdateGleamFirstUsed, UpdateProfessionalExperience,
}
import app/ui/inputs
import app/ui/text
import app/ui/section
import app/ui/tidbit
import app/survey/about_you
import app/survey/programming
import app/survey/gleam
import gleam/option.{None, Some}
import gleam/dynamic.{Dynamic}
import lustre
import lustre/event
import lustre/attribute
import lustre/cmd.{Cmd}
import lustre/element.{Element}

// MAIN ------------------------------------------------------------------------

///
pub fn main(selector: String, query: String) -> Nil {
  // Starting a lustre app can fail if the selector is invalid or if no element
  // matching that selector can be found. Failing would be a bit of a disaster
  // for us so we'll just assert that it never does and hope for the best!
  assert Ok(_) =
    #(loop.init(query), cmd.none())
    |> lustre.application(update, render)
    |> lustre.start(selector)

  Nil
}

fn update(state: State, action: Action) -> #(State, Cmd(Action)) {
  case action {
    Noop -> #(state, cmd.none())

    UpdateProfessionalExperience(timeframe) -> #(
      State(..state, professional_experience: timeframe),
      cmd.none(),
    )

    UpdateGleamFirstUsed(timeframe) -> #(
      State(..state, gleam_first_used: timeframe),
      cmd.none(),
    )
  }
}

// RENDER ----------------------------------------------------------------------

fn render(state: State) -> Element(Action) {
  case state.thank_you {
    True -> render_thanks()
    False -> render_survey(state)
  }
}

fn render_thanks() -> Element(Action) {
  section.render([
    element.h1(
      [attribute.class("max-w-xl mx-auto font-medium text-3xl text-pink")],
      [element.text("Thank you! 💖")],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          "Please share this survey with any of your friends who use or are interested in Gleam!",
        ),
      ],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [element.a([attribute.href("/")], [element.text("Return to the survey")])],
    ),
  ])
}

external fn prevent_default(event: Dynamic) -> Nil =
  "ffi/event.mjs" "preventDefault"

external fn get_event_key(event: Dynamic) -> String =
  "ffi/event.mjs" "getEventKey"

fn render_survey(state: State) -> Element(Action) {
  // This is a long form and in testing we found that users might accidentally
  // submit it early by hitting enter, so we disable this behaviour.
  let prevent_enter_submit = fn(event, _dispatch) {
    case get_event_key(event) {
      "Enter" -> prevent_default(event)
      _ -> Nil
    }
  }

  element.form(
    [
      attribute.action("/entries"),
      attribute.attribute("method", "POST"),
      event.on("keyPress", prevent_enter_submit),
      event.on("keyDown", prevent_enter_submit),
      event.on("keyUp", prevent_enter_submit),
    ],
    [
      render_introduction(),
      element.hr([]),
      programming.render(state.professional_experience),
      element.hr([]),
      gleam.render(state.gleam_first_used),
      element.hr([]),
      about_you.render(),
      element.hr([]),
      submit(),
    ],
  )
}

fn submit() -> Element(Action) {
  section.render([
    section.title("Section 4", "And finally", Some("finally"), element.h2),
    text.render_question("Anything else you'd like to tell us? 😃"),
    inputs.text("anything_else"),
    element.div(
      [attribute.class("max-w-xl mx-auto my-8")],
      [
        element.p([], [element.text("That's it! Thank you!")]),
        element.button(
          [attribute.class("bg-pink rounded py-2 px-4 text-charcoal")],
          [element.text("Submit")],
        ),
      ],
    ),
  ])
}

fn render_introduction() -> Element(Action) {
  let title =
    section.title("Welcome to the", "Gleam developer survey!", None, element.h1)

  section.render([
    title,
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " This survey is designed to help us understand the needs of Gleam
            developers and how we can improve the language and tooling. We
            know we have a diverse community of users, and better understanding
            that community will help us steer the ship in the future!
          ",
        ),
      ],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " Don't worry, none of the questions are required! You're free to 
            answer as much or as little as you'd like.
          ",
        ),
      ],
    ),
    tidbit.render_container([
      element.text(
        " Did you know: this survey is written entirely in Gleam! The source code
        is available
        ",
      ),
      element.a(
        [attribute.href("https://github.com/gleam-lang/developer-survey/")],
        [element.text("on GitHub")],
      ),
      element.text("."),
    ]),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " If you have any questions or run into any problems, please reach
            out to @lpil or @hayleigh in the ",
        ),
        element.a(
          [attribute.href("https://discord.gg/Fm8Pwmy")],
          [element.text("Gleam Discord server")],
        ),
        element.text(", or message Louis on Twitter at "),
        element.a(
          [attribute.href("https://twitter.com/louispilfold")],
          [element.text("@louispilfold")],
        ),
        element.text("."),
      ],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [element.text("With that all sorted, let's get started!")],
    ),
  ])
}
