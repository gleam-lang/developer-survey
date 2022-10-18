// IMPORTS ---------------------------------------------------------------------

import lustre/attribute
import lustre/element.{Element}
import gleam/list

// RENDER ----------------------------------------------------------------------

pub fn render(question_name: String, options: List(String)) -> Element(action) {
  element.div(
    [attribute.class("flex flex-col space-y-2")],
    list.map(options, render_option(_, question_name)),
  )
}

fn render_option(option: String, question_name: String) -> Element(action) {
  element.label(
    [],
    [
      element.input([
        attribute.name(question_name <> "[" <> option <> "]"),
        attribute.type_("checkbox"),
      ]),
      element.span([attribute.class("ml-4")], [element.text(option)]),
    ],
  )
}
