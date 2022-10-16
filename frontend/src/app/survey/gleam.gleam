// IMPORTS ---------------------------------------------------------------------

import app/data/likert.{Likert}
import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/select.{Select}
import app/ui/listbox
import app/ui/section
import app/ui/text
import app/ui/tidbit
import app/util/render
import app/util/list as list_extra
import gleam/function
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import lustre/attribute
import lustre/element.{Element}
import lustre/event

// STATE -----------------------------------------------------------------------

pub type State {
  State(
    first_heard: Range,
    first_used: Range,
    recent_project: String,
    targets_used: Select,
    practice: Likert,
    news: Select,
    popular_projects: Select,
  )
}

pub fn init() -> State {
  State(
    first_heard: LessThan("1 month ago"),
    first_used: NA,
    recent_project: "",
    targets_used: select.multi(),
    practice: likert.init(
      [
        "I have a clear idea how to organise a Gleam codebase.",
        "I like to experiment with many different approaches before committing to something concrete.",
        "I use types to scaffold out a program before implementing any functionality.",
        "I practice test-driven development (TDD) with Gleam.",
        "I use version control software like Git to track a project's history.",
        "I start with a program's behaviour first and work out the types after.",
        "A project is only finished when all my tests pass.",
        "A typical Gleam project includes just a few files.",
        "A typical Gleam project contains lots of files and many lines of code.",
        "I tend to consider a project done after a couple of programming sessions.",
        "A project is only finished when all my tests pass.",
        "My Gleam projects tend to span a long period of time.",
        "I use `todo` a lot to get a work-in-progress to compile.",
      ]
      |> list_extra.shuffle
      |> set.from_list,
    ),
    news: select.multi(),
    popular_projects: select.multi(),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Action {
  UpdateFirstHeard(Range)
  UpdateFirstUsed(Range)
  UpdateRecentProject(String)
  UpdateTargetsUsed(String)
  UpdatePractice(String, Int)
  UpdateNews(String)
  UpdatePopularProjects(String)
}

pub fn update(state: State, action: Action) -> State {
  case action {
    UpdateFirstHeard(range) -> State(..state, first_heard: range)
    UpdateFirstUsed(range) -> State(..state, first_used: range)
    UpdateRecentProject(project) -> State(..state, recent_project: project)
    UpdateTargetsUsed(target) ->
      State(..state, targets_used: select.toggle(state.targets_used, target))
    UpdatePractice(prompt, rating) ->
      State(..state, practice: likert.rate(state.practice, prompt, rating))
    UpdateNews(news) -> State(..state, news: select.toggle(state.news, news))
    UpdatePopularProjects(project) ->
      State(
        ..state,
        popular_projects: select.toggle(state.popular_projects, project),
      )
  }
}

// RENDER ----------------------------------------------------------------------

pub fn render(state: State) -> Element(Action) {
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
        listbox.render(
          range.to_string(state.first_heard, None),
          list.map(
            [
              LessThan("1 month ago"),
              Between("1", "6 months ago"),
              Between("6 months", "1 year ago"),
              MoreThan("1 year ago"),
            ],
            range.to_string(_, None),
          ),
          function.compose(range.from_string, UpdateFirstHeard),
        ),
      ],
    ),
    // Length using gleam ------------------------------------------------------
    text.render_question("How long have you been using Gleam?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.first_used, Some("haven't started yet")),
          list.map(
            [
              NA,
              LessThan("1 month"),
              Between("1", "6 months"),
              Between("6 months", "1 year"),
              Between("1 year", "2 years"),
              MoreThan("1 years"),
            ],
            range.to_string(_, Some("haven't started yet")),
          ),
          function.compose(range.from_string, UpdateFirstUsed),
        ),
      ],
    ),
    // Recent project ----------------------------------------------------------
    render.when(
      state.first_used != NA,
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
                        "relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none",
                      ),
                    ],
                    [
                      element.textarea([
                        attribute.class(
                          "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900 focus:outline-none h-24",
                        ),
                        event.on_input(fn(value, dispatch) {
                          value
                          |> UpdateRecentProject
                          |> dispatch
                        }),
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
      state.first_used != NA,
      fn() {
        element.fragment([
          text.render_question(
            "Which compile targets have you used with Gleam?",
          ),
          element.div(
            [attribute.class("max-w-xl mx-auto")],
            [
              select.render(
                state.targets_used,
                UpdateTargetsUsed,
                ["Erlang", "JavaScript"],
              ),
            ],
          ),
        ])
      },
    ),
    // Programming practice ----------------------------------------------------
    render.when(
      state.first_used != NA,
      fn() {
        element.fragment([
          //
          tidbit.render(
            "The following statements are designed to help us get an idea of how people
            approach development using Gleam. There aren't any \"right\" answers, so
            don't feel pressured to answer in a certain way.",
          ),
          // How well defined is a Gleam project? ------------------------------
          element.div(
            [
              attribute.class(
                "max-w-4xl mx-auto p-4 border-2 border-charcoal dark:border-zinc-700 rounded",
              ),
            ],
            [
              text.render_question(
                "Thinking about how you approach developing a new project in Gleam...",
              ),
              text.render(
                "These statements will give us a clearer picture on how people
                are using Gleam and whether we can do anything to support them!",
              ),
              likert.render(state.practice, UpdatePractice),
            ],
          ),
        ])
      },
    ),
    // Gleam news --------------------------------------------------------------
    text.render_question("Where do you go for Gleam news and discussion?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        select.render(
          state.news,
          UpdateNews,
          [
            "The Gleam Discord server", "/r/gleamlang", "@gleamlang on Twitter",
            "@louispilfold on Twitter", "erlangforums.com", "GitHub discussions",
          ],
        ),
      ],
    ),
    // Popular Gleam projects --------------------------------------------------
    text.render_question(
      "Have you heard of or used any of these Gleam projects?",
    ),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        select.render(
          state.popular_projects,
          UpdatePopularProjects,
          [
            "gleam-experiments/snag", "gleam-lang/mix_gleam", "gleam-lang/otp",
            "hayleigh-dot-dev/lustre", "hayleigh-dot-dev/nibble", "lpil/nerf",
            "lucasavila00/parser-gleam", "michaeljones/matcha",
            "nakaibuild/nakai", "nicklasxyz/gleam_stats", "rawhat/glisten",
            "rawhat/mist", "tanklesxl/glint", "tynanbe/rad", "tynanbe/shellout",
          ],
        ),
      ],
    ),
    tidbit.render(
      "All the projects listed above are open source and available on GitHub. If
      you haven't heard of any of them, go check them out!",
    ),
  ])
}
