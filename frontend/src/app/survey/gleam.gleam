// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/multiselect
import app/data/loop.{Action, UpdateGleamFirstUsed}
import app/ui/inputs
import app/ui/section
import app/ui/text
import app/ui/tidbit
import app/util/render
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{Element}

const news_sources = [
  "The Gleam Discord server", "/r/gleamlang", "@gleamlang on Twitter",
  "@louispilfold on Twitter", "erlangforums.com", "GitHub discussions",
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
    tidbit.render(
      " Fun fact: some of these questions are based on the work Hayleigh has been
        doing on her PhD researching programming language design. If they suck,
        don't tell her - she'll be sad.",
    ),
    // First heard -------------------------------------------------------------
    text.render_question("When did you first hear about Gleam?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
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
      ],
    ),
    // Length using gleam ------------------------------------------------------
    text.render_question("How long have you been using Gleam?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        inputs.select(
          "duration_using_gleam",
          [
            inputs.on_change(fn(value) {
              UpdateGleamFirstUsed(range.from_string(value))
            }),
          ],
          list.map(
            time_periods,
            range.to_string(_, Some("haven't started yet")),
          ),
        ),
      ],
    ),
    // Recent project ----------------------------------------------------------
    render.when(
      gleam_first_used != NA,
      fn() {
        element.fragment([
          text.render_question(
            "Tell us a little bit about what you've been using Gleam for.",
          ),
          element.div(
            [attribute.class("max-w-xl mx-auto")],
            [
              element.div(
                [attribute.class("relative mt-1")],
                [
                  element.div(
                    [
                      attribute.class(
                        "relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md",
                      ),
                    ],
                    [
                      element.textarea([
                        attribute.name("gleam_usage"),
                        attribute.class(
                          "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900 h-24",
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
          element.div(
            [attribute.class("max-w-xl mx-auto")],
            [multiselect.render("targets_used", ["Erlang", "JavaScript"])],
          ),
        ])
      },
    ),
    // Gleam news --------------------------------------------------------------
    text.render_question("Where do you go for Gleam news and discussion?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [multiselect.render("news_sources_used", news_sources)],
    ),
    text.render_question("Somewhere else?"),
    inputs.text("other_news_source"),
    tidbit.render(
      "All the projects listed above are open source and available on GitHub. If
      you haven't heard of any of them, go check them out!",
    ),
  ])
}
