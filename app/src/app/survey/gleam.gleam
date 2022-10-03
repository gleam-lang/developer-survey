// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/ui/listbox
import app/ui/section
import app/ui/text
import app/ui/tidbit
import gleam/function
import gleam/list
import gleam/option.{Some}
import lustre/attribute
import lustre/element.{Element}

// STATE -----------------------------------------------------------------------

pub type State {
  State(first_heard: Range, first_used: Range)
}

pub fn init() -> State {
  State(first_heard: LessThan("a month ago"), first_used: NA)
}

// UPDATE ----------------------------------------------------------------------

pub type Action {
  UpdateFirstHeard(Range)
  UpdateFirstUsed(Range)
}

pub fn update(state: State, action: Action) -> State {
  case action {
    UpdateFirstHeard(range) -> State(..state, first_heard: range)
    UpdateFirstUsed(range) -> State(..state, first_used: range)
  }
}

// RENDER ----------------------------------------------------------------------

pub fn render(state: State) -> Element(Action) {
  section.render([
    section.title("Section 2", "Gleam", Some("gleam"), element.h2),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " In this section we want to learn about your experience with Gleam.
            How you came across the language, what you use it for, if you're
            using it at work. All that good stuff.
        ",
        ),
      ],
    ),
    tidbit.render(
      " Fun fact: some of these questions are based on the work Hayleigh has been
        doing on her PhD researching programming language design. If they suck,
        don't tell her - she'll be sad.",
    ),
    text.render_question("When did you first hear about Gleam?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.first_heard),
          list.map(
            [
              LessThan("a month ago"),
              Between("1", "6 months ago"),
              Between("6 months", "1 year ago"),
              MoreThan("a year ago"),
            ],
            range.to_string,
          ),
          function.compose(range.from_string, UpdateFirstHeard),
        ),
      ],
    ),
  ])
}
