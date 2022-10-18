// IMPORTS ---------------------------------------------------------------------

import app/data/loop.{
  Action, Noop, State, UpdateGleamFirstUsed, UpdateProfessionalExperience,
}
import app/ui/section
import app/ui/tidbit
import app/survey/about_you
import app/survey/gleam
import gleam/option.{None}
import lustre
import lustre/attribute
import lustre/cmd.{Cmd}
import lustre/element.{Element}

// MAIN ------------------------------------------------------------------------

///
pub fn main(selector: String, _hash: String) -> Nil {
  // Starting a lustre app can fail if the selector is invalid or if no element
  // matching that selector can be found. Failing would be a bit of a disaster
  // for us so we'll just assert that it never does and hope for the best!
  assert Ok(_) =
    #(loop.init(), cmd.none())
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
  element.form(
    [attribute.action("/entries"), attribute.attribute("method", "POST")],
    [
      render_introduction(),
      element.hr([]),
      about_you.render(state.professional_experience),
      element.hr([]),
      gleam.render(state.gleam_first_used),
      section.render([
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
      ]),
    ],
  )
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
          " Don't worry, none of the questions are required! You're free to 
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
          " @lpil or @hayleigh or you can message Louis on Twitter
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
