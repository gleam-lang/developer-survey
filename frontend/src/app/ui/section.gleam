// IMPORTS ---------------------------------------------------------------------

import gleam/option.{None, Option, Some}
import gleam/string
import lustre/attribute.{Attribute}
import lustre/element.{Element}

// RENDER ----------------------------------------------------------------------

pub fn render(children: List(Element(action))) -> Element(action) {
  let classes =
    " space-y-8 max-w-none
      prose prose-stone dark:prose-invert
      text-charcoal dark:text-stone-50
    "

  element.section([attribute.class(classes)], children)
}

/// Render a section's title. The "pretext" argument is rendered above the
/// main text in a smaller, pink, font.
pub fn title(
  pretext: String,
  text: String,
  id: Option(String),
  el: fn(List(Attribute(action)), List(Element(action))) -> Element(action),
) -> Element(action) {
  case id {
    Some(id) ->
      el(
        [attribute.id(id), attribute.class("max-w-xl mx-auto font-medium")],
        [
          element.span(
            [attribute.class("block text-lg text-pink")],
            [element.text(pretext)],
          ),
          element.div(
            [attribute.class("text-3xl")],
            [
              element.a(
                [
                  attribute.class("text-stone-400 mr-2"),
                  attribute.href(string.append("#", id)),
                ],
                [element.text("#")],
              ),
              element.text(text),
            ],
          ),
        ],
      )
    None ->
      el(
        [attribute.class("max-w-xl mx-auto font-medium")],
        [
          element.span(
            [attribute.class("block text-lg text-pink")],
            [element.text(pretext)],
          ),
          element.span(
            [attribute.class("block text-3xl")],
            [element.text(text)],
          ),
        ],
      )
  }
}
