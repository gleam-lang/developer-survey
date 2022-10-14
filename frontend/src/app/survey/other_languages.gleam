// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/select.{Select}
import app/ui/combobox
import app/ui/listbox
import app/ui/section
import app/ui/text
import app/ui/tidbit
import app/util/countries
import app/util/render
import gleam/function
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{Element}
import lustre/event

// STATE -----------------------------------------------------------------------

pub type State {
  State(fave_personal: String, fave_professional: String)
}

pub fn init() -> State {
  State(fave_personal: "", fave_professional: "")
}

// UPDATE ----------------------------------------------------------------------

pub type Action {
  UpdateFavePersonal(String)
  UpdateFaveProfessional(String)
}

pub fn update(state: State, action: Action) -> State {
  case action {
    UpdateFavePersonal(fave_personal) ->
      State(..state, fave_personal: fave_personal)
    UpdateFaveProfessional(fave_professional) ->
      State(..state, fave_professional: fave_professional)
  }
}

// RENDER ----------------------------------------------------------------------

pub fn render(state: State, langs_used: List(String)) -> Element(Action) {
  section.render([
    section.title("Section 3", "Other Languages", Some("languages"), element.h2),
    text.render(
      "We'd like to learn a little more about some of the other languages you've
      used. Plus it's cool to see what kind of backgrounds the community is made
      up of.
      ",
    ),
    text.render_question(
      "From the languages you have used, which is your favourite for personal projects?",
    ),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [listbox.render(state.fave_personal, langs_used, UpdateFavePersonal)],
    ),
    text.render_question(
      "Tell us a little bit about what you've been using Gleam for.",
    ),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.div(
          [attribute.class("relative mt-1")],
          [
            element.div(
              [
                attribute.class(
                  "relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none",
                ),
              ],
              [
                element.textarea([
                  attribute.class(
                    "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900 focus:outline-none h-24",
                  ),
                  event.on_input(fn(value, dispatch) { todo }),
                ]),
              ],
            ),
          ],
        ),
      ],
    ),
  ])
}
