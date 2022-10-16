// IMPORTS ---------------------------------------------------------------------

import gleam/option.{None, Option, Some}
import gleam/set.{Set}
import lustre/attribute
import lustre/element.{Element}
import lustre/event
import gleam/list

// TYPES -----------------------------------------------------------------------

pub type Select {
  Single(Option(String))
  Multi(Set(String))
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn single() -> Select {
  Single(None)
}

pub fn multi() {
  Multi(set.new())
}

// QUERIES ---------------------------------------------------------------------

pub fn selected(select: Select) -> List(String) {
  case select {
    Single(None) -> []
    Single(Some(selected)) -> [selected]
    Multi(selected) -> set.to_list(selected)
  }
}

// MANIPULATIONS ---------------------------------------------------------------

pub fn toggle(select: Select, option: String) -> Select {
  case select {
    Single(None) -> Single(Some(option))
    Single(Some(selected)) if selected == option -> Single(None)
    Single(Some(_)) -> Single(Some(option))
    Multi(selected) ->
      Multi(case set.contains(selected, option) {
        True -> set.delete(selected, option)
        False -> set.insert(selected, option)
      })
  }
}

// RENDER ----------------------------------------------------------------------

pub fn render(
  question_name: String,
  select: Select,
  on_toggle: fn(String) -> action,
  options: List(String),
) -> Element(action) {
  let selected = case select {
    Single(None) -> set.new()
    Single(Some(option)) -> set.insert(set.new(), option)
    Multi(selected) -> selected
  }

  element.div(
    [attribute.class("flex flex-col space-y-2")],
    options
    |> list.map(render_option(_, question_name, selected, on_toggle)),
  )
}

fn render_option(
  option: String,
  question_name: String,
  selected: Set(String),
  on_toggle: fn(String) -> action,
) -> Element(action) {
  element.label(
    [],
    [
      element.input([
        attribute.name(question_name <> "[" <> option <> "]"),
        attribute.type_("checkbox"),
        attribute.checked(set.contains(selected, option)),
        event.on(
          "change",
          fn(_, dispatch) {
            option
            |> on_toggle
            |> dispatch
          },
        ),
      ]),
      element.span([attribute.class("ml-4")], [element.text(option)]),
    ],
  )
}
