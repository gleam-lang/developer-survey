import lustre/event
import lustre/element.{Element}
import lustre/attribute.{Attribute}
import gleam/list
import gleam/dynamic.{Dynamic}

const other = "Other (please specify)"

pub fn text(name: String) -> Element(nothing) {
  element.div(
    [attribute.class("max-w-xl mx-auto")],
    [
      element.div(
        [attribute.class("relative mt-1")],
        [
          element.div(
            [
              attribute.class(
                "relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md",
              ),
            ],
            [
              element.input([
                attribute.name(name),
                attribute.class(
                  "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900",
                ),
              ]),
            ],
          ),
        ],
      ),
    ],
  )
}

pub fn select(
  name: String,
  attributes: List(Attribute(action)),
  options: List(String),
) -> Element(action) {
  let classes =
    "
    relative w-full cursor-default overflow-hidden rounded-lg bg-white
    text-charcoal text-left shadow-md py-2 px-2
    "

  let make_option = fn(option) {
    element.option(
      [attribute.attribute("value", option)],
      [element.text(option)],
    )
  }

  element.div(
    [attribute.class("max-w-xl mx-auto")],
    [
      element.select(
        [attribute.name(name), attribute.class(classes), ..attributes],
        list.map(["", ..options], make_option),
      ),
    ],
  )
}

pub fn select_with_other(
  name: String,
  attributes: List(Attribute(action)),
  options: List(String),
) -> Element(action) {
  let classes =
    "
    relative w-full cursor-default overflow-hidden rounded-lg bg-white
    text-charcoal text-left shadow-md py-2 px-2
    "

  let make_option = fn(option) {
    element.option(
      [attribute.attribute("value", option)],
      [element.text(option)],
    )
  }

  element.div(
    [attribute.class("max-w-xl mx-auto")],
    [
      element.stateful(
        "",
        fn(selected, set_selected) {
          let set = fn(event, _dispatch) {
            set_selected(get_event_target_value(event))
          }

          let options =
            [[""], options, [other]]
            |> list.flatten
            |> list.map(make_option)

          let attributes = [
            event.on("change", set),
            attribute.class(classes),
            ..attributes
          ]

          let children = case selected == other {
            True -> [element.select(attributes, options), text(name)]
            False -> [
              element.select([attribute.name(name), ..attributes], options),
            ]
          }

          element.div([], children)
        },
      ),
    ],
  )
}

// This is an unsafe type cast!
external fn get_event_target_value(event: Dynamic) -> String =
  "ffi/event.mjs" "getEventTargetValue"

// This is an unsafe type cast!
external fn get_event_target_checked(event: Dynamic) -> Bool =
  "ffi/event.mjs" "getEventTargetChecked"

pub fn on_change(make_action: fn(String) -> action) -> Attribute(action) {
  event.on(
    "change",
    fn(event, dispatch) {
      let value = get_event_target_value(event)
      let action = make_action(value)
      dispatch(action)
    },
  )
}

pub fn textarea(name: String) -> Element(action) {
  element.div(
    [attribute.class("max-w-xl mx-auto")],
    [
      element.div(
        [attribute.class("relative mt-1")],
        [
          element.div(
            [
              attribute.class(
                "relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md",
              ),
            ],
            [
              element.textarea([
                attribute.name(name),
                attribute.class(
                  "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900 h-24",
                ),
              ]),
            ],
          ),
        ],
      ),
    ],
  )
}

pub fn multiselect(
  question_name: String,
  options: List(String),
) -> Element(action) {
  element.stateful(
    False,
    fn(other_selected, set) {
      let options =
        options
        |> list.append([other])
        |> list.map(render_multiselect_option(_, question_name, set))

      let other_input = case other_selected {
        True -> [text(question_name <> "_other")]
        False -> []
      }

      element.div(
        [attribute.class("max-w-xl mx-auto")],
        list.append(
          [element.div([attribute.class("flex flex-col space-y-2")], options)],
          other_input,
        ),
      )
    },
  )
}

fn render_multiselect_option(
  option: String,
  question_name: String,
  set_other_selected: fn(Bool) -> Nil,
) -> Element(action) {
  let event_handler = fn(event, _dispatch) {
    let value = get_event_target_checked(event)
    set_other_selected(value)
  }
  let event_handler_attribute = case option == other {
    True -> [event.on("change", event_handler)]
    False -> []
  }

  element.label(
    [],
    [
      element.input([
        attribute.name(question_name <> "[" <> option <> "]"),
        attribute.type_("checkbox"),
        ..event_handler_attribute
      ]),
      element.span([attribute.class("ml-4")], [element.text(option)]),
    ],
  )
}
