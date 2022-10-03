// IMPORTS ---------------------------------------------------------------------

import app/ui/section
import app/ui/tidbit
import app/survey/about_you
import app/survey/gleam
import gleam/option.{None, Some}
import lustre
import lustre/attribute
import lustre/cmd.{Cmd}
import lustre/element.{Element}

// MAIN ------------------------------------------------------------------------

///
pub fn main(selector: String, hash: String) -> Nil {
  // Starting a lustre app can fail if the selector is invalid or if no element
  // matching that selector can be found. Failing would be a bit of a disaster
  // for us so we'll just assert that it never does and hope for the best!
  assert Ok(_) =
    Flags(hash: hash)
    |> init
    |> lustre.application(update, render)
    |> lustre.start(selector)

  Nil
}

// STATE -----------------------------------------------------------------------

pub type Flags {
  Flags(hash: String)
}

pub type State {
  State(about_you: about_you.State, gleam: gleam.State)
}

fn init(_: Flags) -> #(State, Cmd(Action)) {
  let state = State(about_you: about_you.init(), gleam: gleam.init())

  #(state, cmd.none())
}

// UPDATE ----------------------------------------------------------------------

type Action {
  UpdateAboutYou(about_you.Action)
  UpdateGleam(gleam.Action)
}

fn update(state: State, action: Action) -> #(State, Cmd(Action)) {
  let noop = #(state, cmd.none())

  case action {
    UpdateAboutYou(action) -> #(
      State(..state, about_you: about_you.update(state.about_you, action)),
      cmd.none(),
    )
    UpdateGleam(action) -> #(
      State(..state, gleam: gleam.update(state.gleam, action)),
      cmd.none(),
    )
    _ -> noop
  }
}

// RENDER ----------------------------------------------------------------------

fn render(state: State) -> Element(Action) {
  element.fragment([
    render_introduction(),
    state.about_you
    |> about_you.render
    |> element.map(UpdateAboutYou),
    state.gleam
    |> gleam.render
    |> element.map(UpdateGleam),
    render_other_languages(),
    render_missing_features(),
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
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.span(
          [],
          [element.text("The survey is broken up into four sections:")],
        ),
        element.ul(
          [],
          [
            element.li(
              [],
              [element.text("Your background and programming practice")],
            ),
            element.li([], [element.text("Your experience with Gleam")]),
            element.li(
              [],
              [element.text("Your experience with other languages")],
            ),
            element.li(
              [],
              [element.text("Your thoughts on features missing from Gleam")],
            ),
          ],
        ),
      ],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " Don't worry, none of the questions are required 😅. You're free to 
            answer as much or as little as you'd like. If you're pressed for time,
            you can help us the most by completing the first two sections.
          ",
        ),
      ],
    ),
    tidbit.render(
      " Did you know: this survey is written entirely in Gleam! Keep an eye
        out for little hints like this as you work your way through the survey.
      ",
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " If you have any questions or run into any problems, please reach
            out to us in the ",
        ),
        element.a(
          [attribute.href("https://discord.gg/Fm8Pwmy")],
          [element.text("Gleam Discord server")],
        ),
        element.text(
          " @lpil or @hayleigh or you can publicly shame Louis on Twitter
            ",
        ),
        element.a(
          [attribute.href("https://twitter.com/louispilfold")],
          [element.text("@louispilfold")],
        ),
      ],
    ),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [element.text("With that all sorted, let's get started!")],
    ),
  ])
}

fn render_other_languages() -> Element(Action) {
  section.render([
    section.title("Section 3", "Other languages", Some("languages"), element.h2),
  ])
}

fn render_missing_features() -> Element(Action) {
  section.render([
    section.title("Section 4", "Missing features", Some("features"), element.h2),
    tidbit.render(
      " Some of the features listed below will *never* come to Gleam, so don't
        get your hopes up! Instead, consider this an opportunity for us to better
        understand what different Gleam developers enjoy about fancier languages.
      ",
    ),
  ])
}
