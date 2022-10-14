// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/data/select.{Select}
import app/ui/combobox
import app/ui/listbox
import app/ui/section
import app/ui/text
import app/ui/tidbit
import app/util/countries
import app/util/render
import gleam/function
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{Element}
import lustre/event

// STATE -----------------------------------------------------------------------

pub type State {
  State(
    country: String,
    general_experience: Range,
    professional_experience: Range,
    current_role: String,
    company_size: Range,
    langs_used: Select,
  )
}

pub fn init() -> State {
  State(
    country: "Antarctica 🇦🇶",
    general_experience: LessThan("1 year"),
    professional_experience: NA,
    current_role: "",
    company_size: NA,
    langs_used: select.multi(),
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Action {
  UpdateCountry(String)
  UpdateGeneralExperience(Range)
  UpdateProfessionalExperience(Range)
  UpdateCurrentRole(String)
  UpdateCompanySize(Range)
  UpdateLangsUsed(String)
}

pub fn update(state: State, action: Action) -> State {
  case action {
    UpdateCountry(country) -> State(..state, country: country)
    UpdateGeneralExperience(timeframe) ->
      State(..state, general_experience: timeframe)
    UpdateProfessionalExperience(timeframe) ->
      State(..state, professional_experience: timeframe)
    UpdateCurrentRole(role) -> State(..state, current_role: role)
    UpdateCompanySize(timeframe) -> State(..state, company_size: timeframe)
    UpdateLangsUsed(lang) ->
      State(..state, langs_used: select.toggle(state.langs_used, lang))
  }
}

// RENDER ----------------------------------------------------------------------

pub fn render(state: State) -> Element(Action) {
  section.render([
    section.title("Section 1", "About you", Some("about"), element.h2),
    text.render(
      " This section is all about you! We'd like to know a bit about your
        background and programming experience. Maybe Gleam developers are all
        embedded engineers from Sweden? Maybe they're all 20-something students
        from Brazil? We don't know, but we'd like to find out!
      ",
    ),
    // Country -----------------------------------------------------------------
    text.render_question("What country are you based in?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        combobox.render(
          state.country,
          countries.names_and_flags(),
          UpdateCountry,
        ),
      ],
    ),
    // Programming experience --------------------------------------------------
    text.render_question("How long have you been programming?"),
    text.render("Either personally or professionally, whatever's longest!"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.general_experience, None),
          list.map(
            [
              LessThan("1 year"),
              Between("1", "2 years"),
              Between("2", "5 years"),
              Between("5", "10 years"),
              MoreThan("10 years"),
            ],
            range.to_string(_, None),
          ),
          function.compose(range.from_string, UpdateGeneralExperience),
        ),
      ],
    ),
    // Professional experience -------------------------------------------------
    text.render_question("How long have you been programming professionally?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.professional_experience, None),
          list.map(
            [
              NA,
              LessThan("1 year"),
              Between("1", "2 years"),
              Between("2", "5 years"),
              Between("5", "10 years"),
              MoreThan("10 years"),
            ],
            range.to_string(_, None),
          ),
          function.compose(range.from_string, UpdateProfessionalExperience),
        ),
      ],
    ),
    // Current role ------------------------------------------------------------
    render.when(
      state.professional_experience != NA,
      fn() {
        element.fragment([
          text.render_question("What's your current role?"),
          text.render(
            "If you're not working right now, think back to your previous or most recent role.",
          ),
          tidbit.render(
            " Roles and titles are so varied that we thought it would
              be easier to leave this as free-form and then aggregate the results
              manually.",
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
                      element.input([
                        attribute.class(
                          "w-full border-none py-2 pl-3 pr-10 text-sm leading-5 text-gray-900",
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
    // Company size ------------------------------------------------------------
    render.when(
      state.professional_experience != NA,
      fn() {
        element.fragment([
          text.render_question("How many people work at your company?"),
          text.render(
            "If you're not working right now, think back to your previous company.",
          ),
          element.div(
            [attribute.class("max-w-xl mx-auto")],
            [
              listbox.render(
                range.to_string(state.company_size, None),
                list.map(
                  [
                    Between("1", "10 employees"),
                    Between("11", "50 employees"),
                    Between("50", "100 employees"),
                    MoreThan("100 employees"),
                  ],
                  range.to_string(_, None),
                ),
                function.compose(range.from_string, UpdateCompanySize),
              ),
            ],
          ),
        ])
      },
    ),
    // Languages used ------------------------------------------------------------
    text.render_question("Which of the following languages have you used?"),
    text.render("Both personally and at work. Select all that apply."),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        select.render(
          state.langs_used,
          UpdateLangsUsed,
          [
            "C", "C++", "Elixir", "Elm", "Erlang", "Go", "Haskell", "Java",
            "JavaScript", "Kotlin", "PHP", "Python", "Ruby", "Rust", "Scala",
            "Swift", "TypeScript",
          ],
        ),
      ],
    ),
  ])
}
