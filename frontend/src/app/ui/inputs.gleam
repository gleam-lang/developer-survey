import lustre/event
import lustre/element.{Element}
import lustre/attribute.{Attribute}
import gleam/list
import gleam/dynamic.{Dynamic}

pub fn text(name: String) -> Element(nothing) {
  element.div(
    [attribute.class("max-w-xl mx-auto"), attribute.name(name)],
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

  element.select(
    [attribute.name(name), attribute.class(classes), ..attributes],
    list.map(options, make_option),
  )
}

// This is an unsafe type cast!
external fn get_event_target_value(event: Dynamic) -> String =
  "ffi/event.mjs" "getEventTargetValue"

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
