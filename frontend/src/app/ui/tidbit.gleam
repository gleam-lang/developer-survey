//// tidbit
////
//// noun [ C ] US
//// UK  /ˈtɪd.bɪt/ US  /ˈtɪd.bɪt/
//// (UK titbit)
////  
//// a small piece of interesting information, or a small dish of pleasant-tasting
//// food:
////
//// Our guide gave us some interesting tidbits about the history of the castle.
////

// IMPORTS ---------------------------------------------------------------------

import lustre/element.{Element}
import lustre/attribute

// RENDER ----------------------------------------------------------------------

pub fn render(text: String) -> Element(action) {
  render_container([element.text(text)])
}

pub fn render_container(elements: List(Element(action))) -> Element(action) {
  element.aside(
    [attribute.class("max-w-xl mx-auto border-l-8 border-pink pl-4")],
    [
      element.span([attribute.class("mr-1")], [element.text("💡")]),
      ..elements
    ],
  )
}
