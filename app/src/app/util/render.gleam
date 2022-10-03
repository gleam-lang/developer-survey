import lustre/element.{Element}

// RENDER ----------------------------------------------------------------------

pub fn when(cond: Bool, el: fn() -> Element(action)) -> Element(action) {
  case cond {
    True -> el()
    False -> element.text("")
  }
}
