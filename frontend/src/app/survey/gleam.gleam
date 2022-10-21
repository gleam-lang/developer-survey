// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/loop.{Action, UpdateGleamFirstUsed}
import app/ui/inputs
import app/ui/section
import app/ui/text
import app/util/render
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{Element}

const news_sources = [
  "The Gleam Discord server", "/r/gleamlang", "@gleamlang on Twitter",
  "@louispilfold on Twitter", "erlangforums.com", "GitHub discussions",
]

const merchandise = [
  "Earings", "Enamel pins", "Hoodies", "Leggings", "Mugs", "Stickers",
  "T-shirts",
]

const time_periods = [
  NA,
  LessThan("1 month"),
  Between("1", "6 months"),
  Between("6 months", "1 year"),
  Between("1 year", "2 years"),
  MoreThan("2 years"),
]

// RENDER ----------------------------------------------------------------------

pub fn render(gleam_first_used: Range) -> Element(Action) {
  section.render([
    section.title("Section 2", "Gleam", Some("gleam"), element.h2),
    element.p(
      [attribute.class("max-w-xl mx-auto")],
      [
        element.text(
          " In this section we want to learn about your experience with Gleam.
            How you came across the language, what you use it for, if you're
            using it at work. All that good stuff.
        ",
        ),
      ],
    ),
    // First heard -------------------------------------------------------------
    text.render_question("When did you first hear about Gleam?"),
    inputs.select(
      "first_heard_about_gleam",
      [],
      list.map(
        [
          LessThan("1 month ago"),
          Between("1", "6 months ago"),
          Between("6 months", "1 year ago"),
          MoreThan("1 year ago"),
        ],
        range.to_string(_, None),
      ),
    ),
    // Gleam first used --------------------------------------------------------
    text.render_question("What do you like about Gleam?"),
    inputs.textarea("why_do_you_like_gleam"),
    // Gleam future additions --------------------------------------------------
    text.render_question(
      "Is there anything you would like to see added to Gleam or the ecosystem?",
    ),
    inputs.textarea("gleam_future_additions"),
    // Length using gleam ------------------------------------------------------
    text.render_question("How long have you been using Gleam?"),
    inputs.select(
      "duration_using_gleam",
      [
        inputs.on_change(fn(value) {
          UpdateGleamFirstUsed(range.from_string(value))
        }),
      ],
      list.map(time_periods, range.to_string(_, Some("haven't started yet"))),
    ),
    // Recent project ----------------------------------------------------------
    render.when(
      gleam_first_used != NA,
      fn() {
        element.fragment([
          text.render_question(
            "Tell us a little bit about what you've been using Gleam for.",
          ),
          inputs.textarea("gleam_usage"),
        ])
      },
    ),
    // Targets used ------------------------------------------------------------   
    render.when(
      gleam_first_used != NA,
      fn() {
        element.fragment([
          text.render_question(
            "Which compile targets have you used with Gleam?",
          ),
          inputs.multiselect("targets_used", ["Erlang", "JavaScript"]),
        ])
      },
    ),
    // Merchandise -------------------------------------------------------------
    text.render_question("Would you be interested in Gleam merchandise?"),
    inputs.multiselect("merchandise", merchandise),
    // Gleam news --------------------------------------------------------------
    text.render_question("Where do you go for Gleam news and discussion?"),
    inputs.multiselect("news_sources_used", news_sources),
    text.render_question("Somewhere else?"),
    inputs.text("other_news_source"),
  ])
}
