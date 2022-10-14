// IMPORTS ---------------------------------------------------------------------

import gleam/float
import gleam/list

// MANIPULATIONS ---------------------------------------------------------------

pub fn shuffle(items: List(a)) -> List(a) {
  // This is surely a terribly slow way of doing this, but whatever we're only 
  // going to use it on short lists so it's not the end of the world.
  items
  |> list.map(fn(a) { #(a, random()) })
  |> list.sort(fn(a, b) { float.compare(a.1, b.1) })
  |> list.map(fn(a) { a.0 })
}

// EXTERNALS -------------------------------------------------------------------

/// Please don't hurt me Louis
external fn random() -> Float =
  "" "Math.random"
