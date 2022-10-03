//// A combobox is like a listbox with the ability to enter text to select a
//// custom option or filter/search the list of options.

// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic.{Dynamic}
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute.{Attribute}
import lustre/element.{Element}
import lustre/event

// RENDER ----------------------------------------------------------------------

pub fn render(
  selected: String,
  options: List(String),
  on_change: fn(String) -> action,
) -> Element(action) {
  element.stateful(
    selected,
    fn(query, set_query) {
      let options_classes =
        attribute.class(
          " absolute mt-2 max-h-60 w-full overflow-auto rounded-md bg-white 
            shadow-lg z-10 text-sm focus:outline-none
          ",
        )

      element.div(
        [attribute.class("relative not-prose")],
        [
          ext_combobox(
            [
              attribute.value(dynamic.from(selected)),
              event.on("change", change_handler(on_change, set_query)),
            ],
            [
              render_input(query_handler(set_query)),
              ext_combobox_options(
                [options_classes],
                options
                |> filter_options(query)
                |> list.map(render_option),
              ),
            ],
          ),
        ],
      )
    },
  )
}

fn render_input(handler: fn(Dynamic, fn(a) -> Nil) -> Nil) -> Element(a) {
  let container_classes =
    attribute.class(
      " relative w-full cursor-default overflow-hidden rounded-lg bg-white
        text-left shadow-md focus:outline-none
      ",
    )

  let input_classes =
    attribute.class(
      " w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900",
    )

  let button_classes =
    attribute.class(
      " absolute inset-y-0 right-0 flex justify-center items-center w-6
        bg-stone-300 cursor-pointer",
    )

  element.div(
    [attribute.class("relative mt-1")],
    [
      element.div(
        [container_classes],
        [
          ext_combobox_input([input_classes, event.on("change", handler)], []),
          ext_combobox_button([button_classes], [element.text(":")]),
        ],
      ),
    ],
  )
}

fn render_option(option: String) -> Element(a) {
  ext_combobox_option(
    [
      attribute.attribute("key", option),
      attribute.class("p-2 cursor-pointer hover:bg-pink"),
      attribute.value(dynamic.from(option)),
    ],
    [element.text(option)],
  )
}

//

fn filter_options(query: String) -> fn(List(String)) -> List(String) {
  list.filter(_, fn(option) {
    option
    |> string.lowercase
    |> string.contains(string.lowercase(query))
  })
}

fn change_handler(
  on_change: fn(String) -> action,
  set_query: fn(String) -> Nil,
) -> fn(Dynamic, fn(action) -> Nil) -> Nil {
  fn(event, global_dispatch) {
    assert Ok(value) = dynamic.string(event)

    global_dispatch(on_change(value))
    set_query(value)
  }
}

fn query_handler(set_query: fn(String) -> Nil) -> fn(Dynamic, a) -> Nil {
  fn(event, _) {
    event
    |> dynamic.field("target", dynamic.field("value", dynamic.string))
    |> result.map(set_query)
    |> result.unwrap(Nil)
  }
}

// EXTERNALS -------------------------------------------------------------------

external fn ext_combobox(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox"

external fn ext_combobox_input(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox_input"

external fn ext_combobox_button(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox_button"

external fn ext_combobox_options(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox_options"

external fn ext_combobox_option(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox_option"

external fn ext_combobox_label(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "combobox_label"
