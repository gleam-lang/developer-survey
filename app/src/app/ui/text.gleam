// IMPORTS ---------------------------------------------------------------------

import lustre/attribute
import lustre/element.{Element}

// RENDER ----------------------------------------------------------------------

pub fn render(text: String) -> Element(action) {
  element.p([attribute.class("max-w-xl mx-auto")], [element.text(text)])
}

pub fn render_question(text: String) -> Element(action) {
  element.p(
    [attribute.class("max-w-xl mx-auto text-lg font-bold")],
    [element.text(text)],
  )
}
