// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic.{Dynamic}
import gleam/list
import lustre/attribute.{Attribute}
import lustre/element.{Element}
import lustre/event

// RENDER ----------------------------------------------------------------------

pub fn render(
  name: String,
  selected: String,
  options: List(String),
  on_change: fn(String) -> action,
) {
  let options_classes =
    attribute.class(
      " absolute mt-2 max-h-60 w-full overflow-auto rounded-md bg-white 
        shadow-lg z-10 text-sm focus:outline-none text-gray-900
      ",
    )

  element.div(
    [attribute.class("relative not-prose")],
    [
      ext_listbox(
        [
          attribute.value(dynamic.from(selected)),
          event.on("change", change_handler(on_change)),
        ],
        [
          render_selection(selected),
          ext_listbox_options(
            [attribute.name(name), options_classes],
            list.map(options, render_option),
          ),
        ],
      ),
    ],
  )
}

fn render_selection(selected: String) -> Element(a) {
  let container_classes =
    attribute.class(
      " relative w-full cursor-default overflow-hidden rounded-lg bg-white
        text-left shadow-md focus:outline-none py-1
      ",
    )
  let selection_classes =
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
      ext_listbox_button(
        [container_classes],
        [
          element.span([selection_classes], [element.text(selected)]),
          element.span([button_classes], [element.text(":")]),
        ],
      ),
    ],
  )
}

fn render_option(option: String) -> Element(a) {
  ext_listbox_option(
    [
      attribute.attribute("key", option),
      attribute.class("p-2 cursor-pointer hover:bg-pink"),
      attribute.value(dynamic.from(option)),
    ],
    [element.text(option)],
  )
}

fn change_handler(
  on_change: fn(String) -> action,
) -> fn(Dynamic, fn(action) -> Nil) -> Nil {
  fn(event, dispatch) {
    assert Ok(value) = dynamic.string(event)

    on_change(value)
    |> dispatch
  }
}

// EXTERNALS -------------------------------------------------------------------

external fn ext_listbox(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "listbox"

external fn ext_listbox_button(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "listbox_button"

external fn ext_listbox_options(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "listbox_options"

external fn ext_listbox_option(
  attrs: List(Attribute(action)),
  children: List(Element(action)),
) -> Element(action) =
  "ffi/headlessui" "listbox_option"
// external fn ext_listbox_label(
//   attrs: List(Attribute(action)),
//   children: List(Element(action)),
// ) -> Element(action) =
//   "ffi/headlessui" "listbox_label"
