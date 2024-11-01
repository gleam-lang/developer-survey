import decode/zero
import gleam/dict
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/json
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/string_builder
import storail
import tempo/datetime
import wisp.{type Request, type Response}
import youid/uuid

pub fn handle_request(req: Request) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case req.method {
    Get -> show_form(req)
    Post -> handle_form_submission(req)
    _ -> wisp.method_not_allowed(allowed: [Get, Post])
  }
}

pub fn show_form(req: Request) -> Response {
  let html = case wisp.get_cookie(req, cookie_name, wisp.PlainText) {
    Ok(_) -> post_submit_html
    Error(_) -> survey_html
  }

  wisp.ok()
  |> wisp.html_body(string_builder.from_string(html))
}

pub fn handle_form_submission(req: Request) -> Response {
  use formdata <- wisp.require_form(req)
  let names = set.from_list(question_names)
  let id = uuid.v7_string()

  let answers =
    formdata.values
    |> list.filter(fn(pair) { set.contains(names, pair.0) })
    |> list.group(fn(pair) { pair.0 })
    |> dict.to_list
    |> list.map(fn(pair) {
      #(pair.0, list.map(pair.1, pair.second) |> string.join(","))
    })

  let assert Ok(_) =
    data_collection()
    |> storail.key(id)
    |> storail.write([
      #("id", id),
      #("ip", request.get_header(req, "x-forwarded-for") |> result.unwrap("")),
      #("inserted-at", datetime.now_utc() |> datetime.to_string),
      ..answers
    ])

  wisp.ok()
  |> wisp.set_cookie(req, cookie_name, "🥰", wisp.PlainText, 60 * 60 * 24 * 90)
  |> wisp.html_body(string_builder.from_string(post_submit_html))
}

fn data_collection() {
  let config =
    storail.Config(data_directory: "data", temporary_directory: "tmp")
  storail.Collection(
    name: "submission",
    config:,
    to_json: fn(data) {
      list.map(data, pair.map_second(_, json.string)) |> json.object
    },
    decoder: zero.dict(zero.string, zero.string) |> zero.map(dict.to_list),
  )
}

const question_names = [
  // Show if Gleam user
  "gleam-experience", "gleam-open-source", "gleam-targets", "writing-libraries",
  "writing-applications", "gleam-runtimes",
  // Show if Gleam prod user
  "gleam-in-production", "company-name",
  // Always show
  "programming-experience", "languages-other-than-gleam", "gleam-news-sources",
  "country", "gleam-likes", "gleam-dislikes", "job-title", "job-industry",
  "job-company-size", "production-os", "development-os", "anything-else",
]

// "gleam-experience", 
// "writing-libraries", "writing-applications", "gleam-runtimes",
// // Always show
// "programming-experience", "languages-other-than-gleam",
// "gleam-news-sources", "country", "gleam-likes", "gleam-dislikes", "job-title",
// "job-industry", "job-company-size", "production-os", "development-os",

const survey_html = "
<!doctype html>
<html lang='en-gb'>
<head>
  <style>
    [data-show-if] {
      display: none;
    }
  </style>
</head>
<body>
  <form method='post'>
    <fieldset>
      <legend>What country are you from?</legend>
      <input type='text' list='countries' name='country'>
    </fieldset>

    <fieldset>
      <legend>Do you use Gleam?</legend>
      <label><input type='radio' name='gleam-user' value='true'>Yes</label>
      <label><input type='radio' name='gleam-user' value='false'>No</label>
    </fieldset>

    <section data-show-if='gleam-user=true'>
      <fieldset>
        <legend>Do you use Gleam in production?</legend>
        <label><input type='radio' name='gleam-in-production' value='true'>Yes</label>
        <label><input type='radio' name='gleam-in-production' value='false'>No</label>
      </fieldset>

      <section data-show-if='gleam-in-production=true'>
        <fieldset>
          <legend>What is your company name?</legend>
          <input type='text' name='company-name'>
        </fieldset>
      </section>

      <fieldset>
        <legend>Do you use Gleam for open source?</legend>
        <label><input type='radio' name='gleam-open-source' value='true'>Yes</label>
        <label><input type='radio' name='gleam-open-source' value='false'>No</label>
      </fieldset>

      <fieldset>
        <legend>What Gleam compilation targets do you use?</legend>
        <label><input type='checkbox' name='gleam-targets' value='erlang'>Erlang</label>
        <label><input type='checkbox' name='gleam-targets' value='javascript'>JavaScript</label>
        <label><input type='checkbox' name='gleam-targets' value='unsure'>Unsure</label>
      </fieldset>
    </section>

    <fieldset>
      <legend>Anything else you'd like to say?</legend>
      <textarea name='anything-else'></textarea>
    </fieldset>

    <input type='submit' value='Submit'>
  </form>

  <script type='module'>
    for (const element of document.querySelectorAll('[data-show-if]')) {
      const [name, value] = element.dataset.showIf.split('=');
      for (const input of document.querySelectorAll(`input[name='${name}']`)) {
        const handle = () => {
          if (input.checked) {
            element.style.display = input.value === value ? 'block' : 'none';
          }
        };
        input.addEventListener('change', handle);
        handle();
      }
    }
  </script>

  <datalist id='countries'>
    <option value=\"Albania\"></option>
    <option value=\"Åland Islands\"></option>
    <option value=\"Algeria\"></option>
    <option value=\"American Samoa\"></option>
    <option value=\"Andorra\"></option>
    <option value=\"Angola\"></option>
    <option value=\"Anguilla\"></option>
    <option value=\"Antarctica\"></option>
    <option value=\"Antigua and Barbuda\"></option>
    <option value=\"Argentina\"></option>
    <option value=\"Armenia\"></option>
    <option value=\"Aruba\"></option>
    <option value=\"Australia\"></option>
    <option value=\"Austria\"></option>
    <option value=\"Azerbaijan\"></option>
    <option value=\"Bahamas (the)\"></option>
    <option value=\"Bahrain\"></option>
    <option value=\"Bangladesh\"></option>
    <option value=\"Barbados\"></option>
    <option value=\"Belarus\"></option>
    <option value=\"Belgium\"></option>
    <option value=\"Belize\"></option>
    <option value=\"Benin\"></option>
    <option value=\"Bermuda\"></option>
    <option value=\"Bhutan\"></option>
    <option value=\"Bolivia (Plurinational State of)\"></option>
    <option value=\"Bonaire, Sint Eustatius and Saba\"></option>
    <option value=\"Bosnia and Herzegovina\"></option>
    <option value=\"Botswana\"></option>
    <option value=\"Bouvet Island\"></option>
    <option value=\"Brazil\"></option>
    <option value=\"British Indian Ocean Territory (the)\"></option>
    <option value=\"Brunei Darussalam\"></option>
    <option value=\"Bulgaria\"></option>
    <option value=\"Burkina Faso\"></option>
    <option value=\"Burundi\"></option>
    <option value=\"Cabo Verde\"></option>
    <option value=\"Cambodia\"></option>
    <option value=\"Cameroon\"></option>
    <option value=\"Canada\"></option>
    <option value=\"Cayman Islands (the)\"></option>
    <option value=\"Central African Republic (the)\"></option>
    <option value=\"Chad\"></option>
    <option value=\"Chile\"></option>
    <option value=\"China\"></option>
    <option value=\"Christmas Island\"></option>
    <option value=\"Cocos (Keeling) Islands (the)\"></option>
    <option value=\"Colombia\"></option>
    <option value=\"Comoros (the)\"></option>
    <option value=\"Congo (the Democratic Republic of the)\"></option>
    <option value=\"Congo (the)\"></option>
    <option value=\"Cook Islands (the)\"></option>
    <option value=\"Costa Rica\"></option>
    <option value=\"Croatia\"></option>
    <option value=\"Cuba\"></option>
    <option value=\"Curaçao\"></option>
    <option value=\"Cyprus\"></option>
    <option value=\"Czechia\"></option>
    <option value=\"Côte d'Ivoire\"></option>
    <option value=\"Denmark\"></option>
    <option value=\"Djibouti\"></option>
    <option value=\"Dominica\"></option>
    <option value=\"Dominican Republic (the)\"></option>
    <option value=\"Ecuador\"></option>
    <option value=\"Egypt\"></option>
    <option value=\"El Salvador\"></option>
    <option value=\"Equatorial Guinea\"></option>
    <option value=\"Eritrea\"></option>
    <option value=\"Estonia\"></option>
    <option value=\"Eswatini\"></option>
    <option value=\"Ethiopia\"></option>
    <option value=\"Falkland Islands (the) [Malvinas]\"></option>
    <option value=\"Faroe Islands (the)\"></option>
    <option value=\"Fiji\"></option>
    <option value=\"Finland\"></option>
    <option value=\"France\"></option>
    <option value=\"French Guiana\"></option>
    <option value=\"French Polynesia\"></option>
    <option value=\"French Southern Territories (the)\"></option>
    <option value=\"Gabon\"></option>
    <option value=\"Gambia (the)\"></option>
    <option value=\"Georgia\"></option>
    <option value=\"Germany\"></option>
    <option value=\"Ghana\"></option>
    <option value=\"Gibraltar\"></option>
    <option value=\"Greece\"></option>
    <option value=\"Greenland\"></option>
    <option value=\"Grenada\"></option>
    <option value=\"Guadeloupe\"></option>
    <option value=\"Guam\"></option>
    <option value=\"Guatemala\"></option>
    <option value=\"Guernsey\"></option>
    <option value=\"Guinea\"></option>
    <option value=\"Guinea-Bissau\"></option>
    <option value=\"Guyana\"></option>
    <option value=\"Haiti\"></option>
    <option value=\"Heard Island and McDonald Islands\"></option>
    <option value=\"Holy See (the)\"></option>
    <option value=\"Honduras\"></option>
    <option value=\"Hong Kong\"></option>
    <option value=\"Hungary\"></option>
    <option value=\"Iceland\"></option>
    <option value=\"India\"></option>
    <option value=\"Indonesia\"></option>
    <option value=\"Iran (Islamic Republic of)\"></option>
    <option value=\"Iraq\"></option>
    <option value=\"Ireland\"></option>
    <option value=\"Isle of Man\"></option>
    <option value=\"Israel\"></option>
    <option value=\"Italy\"></option>
    <option value=\"Jamaica\"></option>
    <option value=\"Japan\"></option>
    <option value=\"Jersey\"></option>
    <option value=\"Jordan\"></option>
    <option value=\"Kazakhstan\"></option>
    <option value=\"Kenya\"></option>
    <option value=\"Kiribati\"></option>
    <option value=\"Korea (the Democratic People's Republic of)\"></option>
    <option value=\"Korea (the Republic of)\"></option>
    <option value=\"Kuwait\"></option>
    <option value=\"Kyrgyzstan\"></option>
    <option value=\"Lao People's Democratic Republic (the)\"></option>
    <option value=\"Latvia\"></option>
    <option value=\"Lebanon\"></option>
    <option value=\"Lesotho\"></option>
    <option value=\"Liberia\"></option>
    <option value=\"Libya\"></option>
    <option value=\"Liechtenstein\"></option>
    <option value=\"Lithuania\"></option>
    <option value=\"Luxembourg\"></option>
    <option value=\"Macao\"></option>
    <option value=\"Madagascar\"></option>
    <option value=\"Malawi\"></option>
    <option value=\"Malaysia\"></option>
    <option value=\"Maldives\"></option>
    <option value=\"Mali\"></option>
    <option value=\"Malta\"></option>
    <option value=\"Marshall Islands (the)\"></option>
    <option value=\"Martinique\"></option>
    <option value=\"Mauritania\"></option>
    <option value=\"Mauritius\"></option>
    <option value=\"Mayotte\"></option>
    <option value=\"Mexico\"></option>
    <option value=\"Micronesia (Federated States of)\"></option>
    <option value=\"Moldova (the Republic of)\"></option>
    <option value=\"Monaco\"></option>
    <option value=\"Mongolia\"></option>
    <option value=\"Montenegro\"></option>
    <option value=\"Montserrat\"></option>
    <option value=\"Morocco\"></option>
    <option value=\"Mozambique\"></option>
    <option value=\"Myanmar\"></option>
    <option value=\"Namibia\"></option>
    <option value=\"Nauru\"></option>
    <option value=\"Nepal\"></option>
    <option value=\"Netherlands (the)\"></option>
    <option value=\"New Caledonia\"></option>
    <option value=\"New Zealand\"></option>
    <option value=\"Nicaragua\"></option>
    <option value=\"Niger (the)\"></option>
    <option value=\"Nigeria\"></option>
    <option value=\"Niue\"></option>
    <option value=\"Norfolk Island\"></option>
    <option value=\"Northern Mariana Islands (the)\"></option>
    <option value=\"Norway\"></option>
    <option value=\"Oman\"></option>
    <option value=\"Pakistan\"></option>
    <option value=\"Palau\"></option>
    <option value=\"Palestine, State of\"></option>
    <option value=\"Panama\"></option>
    <option value=\"Papua New Guinea\"></option>
    <option value=\"Paraguay\"></option>
    <option value=\"Peru\"></option>
    <option value=\"Philippines (the)\"></option>
    <option value=\"Pitcairn\"></option>
    <option value=\"Poland\"></option>
    <option value=\"Portugal\"></option>
    <option value=\"Puerto Rico\"></option>
    <option value=\"Qatar\"></option>
    <option value=\"Republic of North Macedonia\"></option>
    <option value=\"Romania\"></option>
    <option value=\"Russian Federation (the)\"></option>
    <option value=\"Rwanda\"></option>
    <option value=\"Réunion\"></option>
    <option value=\"Saint Barthélemy\"></option>
    <option value=\"Saint Helena, Ascension and Tristan da Cunha\"></option>
    <option value=\"Saint Kitts and Nevis\"></option>
    <option value=\"Saint Lucia\"></option>
    <option value=\"Saint Martin (French part)\"></option>
    <option value=\"Saint Pierre and Miquelon\"></option>
    <option value=\"Saint Vincent and the Grenadines\"></option>
    <option value=\"Samoa\"></option>
    <option value=\"San Marino\"></option>
    <option value=\"Sao Tome and Principe\"></option>
    <option value=\"Saudi Arabia\"></option>
    <option value=\"Senegal\"></option>
    <option value=\"Serbia\"></option>
    <option value=\"Seychelles\"></option>
    <option value=\"Sierra Leone\"></option>
    <option value=\"Singapore\"></option>
    <option value=\"Sint Maarten (Dutch part)\"></option>
    <option value=\"Slovakia\"></option>
    <option value=\"Slovenia\"></option>
    <option value=\"Solomon Islands\"></option>
    <option value=\"Somalia\"></option>
    <option value=\"South Africa\"></option>
    <option value=\"South Georgia and the South Sandwich Islands\"></option>
    <option value=\"South Sudan\"></option>
    <option value=\"Spain\"></option>
    <option value=\"Sri Lanka\"></option>
    <option value=\"Sudan (the)\"></option>
    <option value=\"Suriname\"></option>
    <option value=\"Svalbard and Jan Mayen\"></option>
    <option value=\"Sweden\"></option>
    <option value=\"Switzerland\"></option>
    <option value=\"Syrian Arab Republic\"></option>
    <option value=\"Taiwan (Province of China)\"></option>
    <option value=\"Tajikistan\"></option>
    <option value=\"Tanzania, United Republic of\"></option>
    <option value=\"Thailand\"></option>
    <option value=\"Timor-Leste\"></option>
    <option value=\"Togo\"></option>
    <option value=\"Tokelau\"></option>
    <option value=\"Tonga\"></option>
    <option value=\"Trinidad and Tobago\"></option>
    <option value=\"Tunisia\"></option>
    <option value=\"Turkey\"></option>
    <option value=\"Turkmenistan\"></option>
    <option value=\"Turks and Caicos Islands (the)\"></option>
    <option value=\"Tuvalu\"></option>
    <option value=\"Uganda\"></option>
    <option value=\"Ukraine\"></option>
    <option value=\"United Arab Emirates (the)\"></option>
    <option value=\"United Kingdom of Great Britain and Northern Ireland (the)\"></option>
    <option value=\"United States Minor Outlying Islands (the)\"></option>
    <option value=\"United States of America (the)\"></option>
    <option value=\"Uruguay\"></option>
    <option value=\"Uzbekistan\"></option>
    <option value=\"Vanuatu\"></option>
    <option value=\"Venezuela (Bolivarian Republic of)\"></option>
    <option value=\"Viet Nam\"></option>
    <option value=\"Virgin Islands (British)\"></option>
    <option value=\"Virgin Islands (U.S.)\"></option>
    <option value=\"Wallis and Futuna\"></option>
    <option value=\"Western Sahara\"></option>
    <option value=\"Yemen\"></option>
    <option value=\"Zambia\"></option>
    <option value=\"Zimbabwe\"></option>
  </datalist>

  <datalist id='languages'>
    <option value='Ada'></option>
    <option value='Apex'></option>
    <option value='Assembly'></option>
    <option value='BASIC'></option>
    <option value='Bash'></option>
    <option value='C#'></option>
    <option value='C'></option>
    <option value='C++'></option>
    <option value='COBOL'></option>
    <option value='Clojure'></option>
    <option value='Crystal'></option>
    <option value='D'></option>
    <option value='Dart'></option>
    <option value='Elixir'></option>
    <option value='Elm'></option>
    <option value='Erlang'></option>
    <option value='F#'></option>
    <option value='Fortran'></option>
    <option value='GDScript'></option>
    <option value='Go'></option>
    <option value='Groovy'></option>
    <option value='Haskell'></option>
    <option value='Idris'></option>
    <option value='Java'></option>
    <option value='JavaScript'></option>
    <option value='Julia'></option>
    <option value='Kotlin'></option>
    <option value='LabVIEW'></option>
    <option value='Lisp'></option>
    <option value='Lua'></option>
    <option value='MATLAB'></option>
    <option value='Nim'></option>
    <option value='OCaml'></option>
    <option value='Odin'></option>
    <option value='PHP'></option>
    <option value='Perl'></option>
    <option value='Pony'></option>
    <option value='Prolog'></option>
    <option value='PureScript'></option>
    <option value='Python'></option>
    <option value='R'></option>
    <option value='Racket'></option>
    <option value='ReScript'></option>
    <option value='Ruby'></option>
    <option value='Rust'></option>
    <option value='Scala'></option>
    <option value='Shell'></option>
    <option value='Smalltalk'></option>
    <option value='Swift'></option>
    <option value='Tcl'></option>
    <option value='TypeScript'></option>
    <option value='V'></option>
    <option value='Visual Basic'></option>
    <option value='Zig'></option>
  </datalist>

</body>
</html>
"

const post_submit_html = "
"

const cookie_name = "gleam-developer-survey-submitted"
