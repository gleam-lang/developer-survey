// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic.{Dynamic}
import gleam/list
import gleam/result
import gleam/string
import gleam/option.{None, Option, Some}
import lustre/attribute.{Attribute}
import lustre/element.{Element}
import lustre/event

// RENDER ----------------------------------------------------------------------

pub fn render_single(
  selected: Option(String),
  options: List(String),
) -> Element(action) {
  element.fieldset([], [])
}

pub fn render_single_with_custom(
  selected: Option(String),
  options: List(String),
  on_select: fn(String) -> action,
  on_add: fn(String) -> action,
  on_remove: fn(String) -> action,
) -> Element(action) {
  todo
}

pub fn render_multi(
  selected: List(String),
  options: List(String),
) -> Element(action) {
  element.stateful(
    [],
    fn(custom_options, set_custom_options) { element.fieldset([], []) },
  )
}

pub fn render_multi_with_custom(
  selected: List(String),
  options: List(String),
  on_select: fn(String) -> action,
) -> Element(action) {
  todo
}

fn render_option(
  option: String,
  selected: List(String),
  on_select: fn(String) -> action,
) -> Element(action) {
  todo
}

fn render_custom_option(
  option: String,
  selected: List(String),
  on_select: fn(String) -> action,
  on_add: fn(String) -> action,
  on_remove: fn(String) -> action,
) -> Element(action) {
  todo
}
