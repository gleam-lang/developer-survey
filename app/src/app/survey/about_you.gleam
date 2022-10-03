// IMPORTS ---------------------------------------------------------------------

import app/data/range.{Between, LessThan, MoreThan, NA, Range}
import app/ui/combobox
import app/ui/listbox
import app/ui/section
import app/ui/text
import app/util/countries
import app/util/render
import gleam/function
import gleam/list
import gleam/option.{Some}
import lustre/attribute
import lustre/element.{Element}

// STATE -----------------------------------------------------------------------

pub type State {
  State(
    country: String,
    general_experience: Range,
    professional_experience: Range,
    company_size: Range,
  )
}

pub fn init() -> State {
  State(
    country: "Antarctica 🇦🇶",
    general_experience: LessThan("1 year"),
    professional_experience: NA,
    company_size: NA,
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Action {
  UpdateCountry(String)
  UpdateGeneralExperience(Range)
  UpdateProfessionalExperience(Range)
  UpdateCompanySize(Range)
}

pub fn update(state: State, action: Action) -> State {
  case action {
    UpdateCountry(country) -> State(..state, country: country)
    //
    UpdateGeneralExperience(timeframe) ->
      State(..state, general_experience: timeframe)
    //
    UpdateProfessionalExperience(timeframe) ->
      State(..state, professional_experience: timeframe)
    //
    UpdateCompanySize(timeframe) -> State(..state, company_size: timeframe)
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
    text.render_question("How long have you been programming?"),
    text.render("Either personally or professionally, whatever's longest!"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.general_experience),
          list.map(
            [
              LessThan("1 year"),
              Between("1", "2 years"),
              Between("2", "5 years"),
              Between("5", "10 years"),
              MoreThan("10 years"),
            ],
            range.to_string,
          ),
          function.compose(range.from_string, UpdateGeneralExperience),
        ),
      ],
    ),
    text.render_question("How long have you been programming professionally?"),
    element.div(
      [attribute.class("max-w-xl mx-auto")],
      [
        listbox.render(
          range.to_string(state.professional_experience),
          list.map(
            [
              NA,
              LessThan("1 year"),
              Between("1", "2 years"),
              Between("2", "5 years"),
              Between("5", "10 years"),
              MoreThan("10 years"),
            ],
            range.to_string,
          ),
          function.compose(range.from_string, UpdateProfessionalExperience),
        ),
      ],
    ),
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
                range.to_string(state.company_size),
                list.map(
                  [
                    Between("1", "10 employees"),
                    Between("11", "50 employees"),
                    Between("50", "100 employees"),
                    MoreThan("100 employees"),
                  ],
                  range.to_string,
                ),
                function.compose(range.from_string, UpdateCompanySize),
              ),
            ],
          ),
        ])
      },
    ),
  ])
}
