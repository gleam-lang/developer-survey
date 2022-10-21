import app/data/range.{Range}
import gleam/string

// STATE -----------------------------------------------------------------------

pub type State {
  State(
    thank_you: Bool,
    professional_experience: Range,
    gleam_first_used: Range,
  )
}

pub fn init(query: String) -> State {
  State(
    professional_experience: range.NA,
    gleam_first_used: range.NA,
    thank_you: string.contains(query, "thank-you"),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Action {
  Noop
  UpdateGleamFirstUsed(Range)
  UpdateProfessionalExperience(Range)
}
