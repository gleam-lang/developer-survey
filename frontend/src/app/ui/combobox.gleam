//// A combobox is like a listbox with the ability to enter text to select a
//// custom option or filter/search the list of options.

// IMPORTS ---------------------------------------------------------------------

import gleam/list
import lustre/attribute
import lustre/element.{Element}

// RENDER ----------------------------------------------------------------------

pub fn render(name: String, options: List(String)) -> Element(action) {
  let classes =
    "
    relative w-full cursor-default overflow-hidden rounded-lg bg-white
    text-charcoal text-left shadow-md focus:outline-none py-2 px-2
    "

  element.select(
    [attribute.name(name), attribute.class(classes)],
    list.map(options, render_option),
  )
}

fn render_option(option: String) -> Element(action) {
  element.option([attribute.attribute("value", option)], [element.text(option)])
}
