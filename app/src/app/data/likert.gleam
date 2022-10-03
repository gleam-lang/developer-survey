// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic
import gleam/list
import gleam/map.{Map}
import lustre/attribute
import lustre/element.{Element}
import lustre/event
import gleam/int

// TYPES -----------------------------------------------------------------------

pub opaque type Likert {
  Likert(scale: Scale, items: Map(String, Item))
}

type Item {
  Item(label: String, rating: Rating)
}

type Scale {
  Three
  Five
  Seven
}

pub opaque type Rating {
  StronglyDisagree
  Disagree
  SomewhatDisagree
  Neutral
  SomewhatAgree
  Agree
  StronglyAgree
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn threepoint(items: List(#(String, String))) -> Likert {
  Likert(Three, to_item_map(items))
}

pub fn fivepoint(items: List(#(String, String))) -> Likert {
  Likert(Five, to_item_map(items))
}

pub fn sevenpoint(items: List(#(String, String))) -> Likert {
  Likert(Seven, to_item_map(items))
}

fn to_item_map(items: List(#(String, String))) -> Map(String, Item) {
  list.fold(
    items,
    map.new(),
    fn(map, item) { map.insert(map, item.0, Item(item.1, Neutral)) },
  )
}

external fn random_int() -> Int =
  "ffi/random.mjs" "int"

pub fn props(
  likert: Likert,
  on_rating: fn(String, Rating) -> action,
) -> Props(action) {
  Props(likert: likert, title: "", description: "", on_rating: on_rating)
}

/// This is an *internal* function so we're being kind of lazy and defaulting
/// to `Neutral` on any unexpected input. 
fn rating_from_string(string: String) -> Rating {
  case string {
    "Strongly Disagree" -> StronglyDisagree
    "Disagree" -> Disagree
    "Somewhat Disagree" -> SomewhatDisagree
    "Neutral" -> Neutral
    "Somewhat Agree" -> SomewhatAgree
    "Agree" -> Agree
    "Strongly Agree" -> StronglyAgree
    _ -> Neutral
  }
}

fn rating_from_int(int: Int) -> Rating {
  case int {
    _ if int <= -3 -> StronglyDisagree
    -2 -> Disagree
    -1 -> SomewhatDisagree
    0 -> Neutral
    1 -> SomewhatAgree
    2 -> Agree
    _ if int >= 3 -> StronglyAgree
  }
}

// QUERIES ---------------------------------------------------------------------

pub fn items(likert: Likert) -> List(#(String, String, Int)) {
  map.fold(
    likert.items,
    [],
    fn(list, id, item) {
      [#(id, item.label, rating_to_int(item.rating)), ..list]
    },
  )
}

// MANIPULATIONS ---------------------------------------------------------------

pub fn rate(likert: Likert, id: String, rating: Rating) -> Likert {
  Likert(
    ..likert,
    items: // We have to do the `map.get .. map.insert` thing because `map.update`
    // *forces* is to return an `Item` even in cases where the key doesn't
    // exist in the map. 😔
    case map.get(likert.items, id) {
      Ok(item) -> map.insert(likert.items, id, Item(..item, rating: rating))
      Error(_) -> likert.items
    },
  )
}

pub fn with_title(props: Props(action), title: String) -> Props(action) {
  Props(..props, title: title)
}

pub fn with_description(
  props: Props(action),
  description: String,
) -> Props(action) {
  Props(..props, description: description)
}

// CONVERSIONS -----------------------------------------------------------------

fn rating_to_int(rating: Rating) -> Int {
  case rating {
    StronglyDisagree -> -3
    Disagree -> -2
    SomewhatDisagree -> -1
    Neutral -> 0
    SomewhatAgree -> 1
    Agree -> 2
    StronglyAgree -> 3
  }
}

fn rating_to_string(rating: Rating) -> String {
  case rating {
    StronglyDisagree -> "Strongly Disagree"
    Disagree -> "Disagree"
    SomewhatDisagree -> "Somewhat Disagree"
    Neutral -> "Neutral"
    SomewhatAgree -> "Somewhat Agree"
    Agree -> "Agree"
    StronglyAgree -> "Strongly Agree"
  }
}

// RENDER ----------------------------------------------------------------------

pub type Props(action) {
  Props(
    likert: Likert,
    title: String,
    description: String,
    on_rating: fn(String, Rating) -> action,
  )
}

pub fn render(props: Props(action)) -> Element(action) {
  let title = case props.title == "" {
    True -> element.text("")
    False -> element.h3([], [element.text(props.title)])
  }

  let description = case props.description == "" {
    True -> element.text("")
    False -> element.p([], [element.text(props.description)])
  }

  let options = case props.likert.scale {
    Three -> [Disagree, Neutral, Agree]
    Five -> [Disagree, SomewhatDisagree, Neutral, SomewhatAgree, Agree]
    Seven -> [
      StronglyDisagree,
      Disagree,
      SomewhatDisagree,
      Neutral,
      SomewhatAgree,
      Agree,
      StronglyAgree,
    ]
  }

  element.div(
    [
      attribute.class(
        "max-w-4xl mx-auto rounded sm:border-2 border-charcoal sm:p-4",
      ),
    ],
    [
      title,
      description,
      element.div(
        [attribute.class("mt-4 space-y-8")],
        [
          render_options(options),
          ..map.to_list(props.likert.items)
          |> list.map(render_item(_, options, props.on_rating))
        ],
      ),
    ],
  )
}

fn render_options(options: List(Rating)) {
  element.div(
    [attribute.class("not-prose md:grid md:grid-cols-12 md:gap-8")],
    [
      element.div([attribute.class("md:col-span-5")], []),
      element.ul(
        [attribute.class("flex justify-between md:col-span-7 font-bold")],
        case list.length(options) {
          3 | 5 -> [
            element.li(
              [attribute.class("w-24 text-left")],
              [element.text("Disagree")],
            ),
            element.li(
              [attribute.class("w-24 text-center")],
              [element.text("Neutral")],
            ),
            element.li(
              [attribute.class("w-24 text-right")],
              [element.text("Agree")],
            ),
          ]
          7 -> [
            element.li(
              [attribute.class("w-24 text-left")],
              [element.text("Strongly Disagree")],
            ),
            element.li(
              [attribute.class("w-24 text-center")],
              [element.text("Neutral")],
            ),
            element.li(
              [attribute.class("w-24 text-right")],
              [element.text("Strongly Agree")],
            ),
          ]
        },
      ),
    ],
  )
}

fn render_item(
  item: #(String, Item),
  options: List(Rating),
  on_rating: fn(String, Rating) -> action,
) -> Element(action) {
  let #(id, item) = item
  let handler = fn(event, dispatch) {
    assert Ok(value) =
      event
      |> dynamic.field("target", dynamic.field("value", dynamic.string))
    assert Ok(value) = int.parse(value)

    value
    |> rating_from_int
    |> on_rating(id, _)
    |> dispatch
  }

  let radio = fn(value) {
    element.input([
      attribute.attribute("title", rating_to_string(value)),
      attribute.checked(value == item.rating),
      attribute.name(id),
      attribute.type_("radio"),
      attribute.value(dynamic.from(rating_to_int(value))),
      event.on("change", handler),
    ])
  }

  element.div(
    [attribute.class("md:grid md:grid-cols-12 md:gap-8 space-y-4 md:space-y-0")],
    [
      element.span(
        [attribute.class("md:col-span-5 text-justify sm:text-left")],
        [element.text(item.label)],
      ),
      element.fieldset(
        [attribute.class("md:col-span-7 flex items-center justify-around")],
        list.map(options, radio),
      ),
    ],
  )
}
