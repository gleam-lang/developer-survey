import app/data/range.{Range}

// STATE -----------------------------------------------------------------------

pub type State {
  State(professional_experience: Range, gleam_first_used: Range)
}

pub fn init() -> State {
  State(professional_experience: range.NA, gleam_first_used: range.NA)
}

// UPDATE ----------------------------------------------------------------------

pub type Action {
  Noop
  UpdateGleamFirstUsed(Range)
  UpdateProfessionalExperience(Range)
}
