// IMPORTS ---------------------------------------------------------------------

import app/route.{Route}
import lustre
import lustre/attribute
import lustre/cmd.{Cmd}
import lustre/element.{Element}

// MAIN ------------------------------------------------------------------------

///
pub fn main(selector: String, hash: String) -> Nil {
  // Starting a lustre app can fail if the selector is invalid or if no element
  // matching that selector can be found. Failing would be a bit of a disaster
  // for us so we'll just assert that it never does and hope for the best!
  assert Ok(_) =
    Flags(hash: hash)
    |> init
    |> lustre.application(update, render)
    |> lustre.start(selector)

  Nil
}

// STATE -----------------------------------------------------------------------

pub type Flags {
  Flags(hash: String)
}

pub type State {
  State(route: Route)
}

fn init(flags: Flags) -> #(State, Cmd(Action)) {
  let #(route, init_router) = route.init(flags.hash, OnRouteChange)
  let state = State(route)

  #(state, cmd.batch([init_router]))
}

// UPDATE ----------------------------------------------------------------------

type Action {
  OnRouteChange(route: Route)
}

fn update(state: State, action: Action) -> #(State, Cmd(Action)) {
  let noop = #(state, cmd.none())
  let current_route = state.route

  case action {
    // There are a few scenarios where this action gets triggered but the actual
    // route didn't change. For example "#", "#/", and "#/info" are all valid
    // hashes for the `Info` route, and changing from one to the other will
    // trigger this action but the app route doesn't need to change. In those
    // cases we just want to noop with no state changes.
    OnRouteChange(route) if route == current_route -> noop
    OnRouteChange(route) -> on_route_change(state, route)
    _ -> noop
  }
}

fn on_route_change(state: State, route: Route) -> #(State, Cmd(Action)) {
  case route {
    route.Info -> #(State(..state, route: route), cmd.none())
    route.Survey(route.Demographics) -> #(
      State(..state, route: route),
      cmd.none(),
    )
    route.Survey(route.Languages) -> #(State(..state, route: route), cmd.none())
    route.Survey(route.Features) -> #(State(..state, route: route), cmd.none())
    route.Complete -> #(State(..state, route: route), cmd.none())
    route.Unknown -> #(State(..state, route: route), cmd.none())
  }
}

// RENDER ----------------------------------------------------------------------

fn render(state: State) -> Element(Action) {
  // This is all just placeholder stuff to make sure routing and rendering is
  // working properly.
  // 
  // An actual app to come soon™️...
  element.div(
    [],
    [
      render_route(state.route),
      element.a([attribute.href("#/info")], [element.text("Info")]),
      element.a(
        [attribute.href("#/survey/demographics")],
        [element.text("Demographics")],
      ),
      element.a(
        [attribute.href("#/survey/languages")],
        [element.text("Languages")],
      ),
      element.a(
        [attribute.href("#/survey/features")],
        [element.text("Features")],
      ),
      element.a([attribute.href("#/complete")], [element.text("Complete")]),
    ],
  )
}

fn render_route(route: Route) -> Element(Action) {
  element.div(
    [],
    [
      element.text("The current route is: "),
      element.text(route.to_string(route)),
    ],
  )
}
