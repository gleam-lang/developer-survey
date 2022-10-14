// IMPORTS ---------------------------------------------------------------------

import lustre/element.{Element}
import lustre/attribute
import lustre/event
import gleam/set.{Set}
import gleam/list
import gleam/dynamic

// TYPES -----------------------------------------------------------------------

pub opaque type Likert {
  Likert(List(#(String, Int)))
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn init(statements: Set(String)) {
  Likert(
    statements
    |> set.to_list
    |> list.map(fn(statement) { #(statement, 0) }),
  )
}

// MANIPULATIONS ---------------------------------------------------------------

pub fn rate(likert: Likert, statement: String, rating: Int) {
  let Likert(items) = likert

  Likert(
    items
    |> list.map(fn(item) {
      case item {
        #(prompt, _) if prompt == statement -> #(prompt, rating)
        _ -> item
      }
    }),
  )
}

// RENDER ----------------------------------------------------------------------

pub fn render(
  likert: Likert,
  on_rate: fn(String, Int) -> action,
) -> Element(action) {
  let Likert(items) = likert
  element.div(
    [attribute.class("not-prose")],
    [
      element.div(
        [
          attribute.class(
            "flex flex-col items-center md:grid md:grid-cols-5 md:gap-4 mb-4",
          ),
        ],
        [
          element.div([attribute.class("md:col-span-3")], []),
          element.div(
            [
              attribute.class(
                "flex-1 w-full flex justify-between md:col-span-2",
              ),
            ],
            [
              element.span(
                [attribute.class("flex-1 text-sm text-left")],
                [element.text("Disagree")],
              ),
              element.span(
                [attribute.class("flex-1 text-sm text-center")],
                [element.text("Neutral")],
              ),
              element.span(
                [attribute.class("flex-1 text-sm text-right")],
                [element.text("Agree")],
              ),
            ],
          ),
        ],
      ),
      element.ul(
        [attribute.class("space-y-4")],
        items
        |> list.map(render_statement(_, on_rate)),
      ),
    ],
  )
}

fn render_statement(
  item: #(String, Int),
  on_rate: fn(String, Int) -> action,
) -> Element(action) {
  let #(prompt, rating) = item
  let render_radio = fn(value) {
    element.input([
      attribute.type_("radio"),
      attribute.name(prompt),
      attribute.value(dynamic.from(value)),
      attribute.checked(value == rating),
      event.on(
        "change",
        fn(_, dispatch) {
          on_rate(prompt, value)
          |> dispatch
        },
      ),
    ])
  }

  element.li(
    [
      attribute.class(
        "flex flex-col items-center md:grid md:grid-cols-5 md:gap-4",
      ),
    ],
    [
      element.span([attribute.class("sm:col-span-3")], [element.text(prompt)]),
      element.fieldset(
        [attribute.class("w-full flex justify-between sm:col-span-2")],
        list.range(-2, 2)
        |> list.map(render_radio),
      ),
    ],
  )
}
