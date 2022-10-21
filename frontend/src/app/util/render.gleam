import lustre/element.{Element}
import lustre/attribute

// RENDER ----------------------------------------------------------------------

pub fn when(cond: Bool, el: fn() -> Element(action)) -> Element(action) {
  element.div([attribute.classes([#("hidden", !cond)])], [el()])
}
