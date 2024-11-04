import decode/zero
import gleam/dict
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/json
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/string_builder
import mist
import storail
import tempo/datetime
import wisp.{type Request, type Response}
import wisp/wisp_mist
import youid/uuid

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.bind("0.0.0.0")
    |> mist.start_http

  process.sleep_forever()
}

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
    Ok(_) -> html_thanks
    Error(_) -> html_form
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
    |> list.filter(fn(pair) { pair.1 != "" })
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
      #("ip", request.get_header(req, "cf-connecting-ip") |> result.unwrap("")),
      #("inserted-at", datetime.now_utc() |> datetime.to_string),
      ..answers
    ])

  wisp.ok()
  |> wisp.set_cookie(req, cookie_name, ":)", wisp.PlainText, 60 * 60 * 24 * 90)
  |> wisp.html_body(string_builder.from_string(html_thanks))
}

fn data_collection() {
  let config =
    storail.Config(data_directory: "data", temporary_directory: "data/tmp")
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
  "projects", "individual-sponsor", "organisation-sponsor", "sponsor-motivation",
  "gleam-user", "gleam-experience", "gleam-open-source", "targets",
  "writing-libraries", "writing-applications", "runtimes", "gleam-in-production",
  "organisation-name", "professional-experience", "other-languages",
  "news-sources", "country", "likes", "improvements", "job-role",
  "organisation-size", "production-os", "development-os", "anything-else",
]

const html_head = "
<!doctype html>
<html lang='en-gb'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width'>
  <link rel='shortcut icon' href='https://gleam.run/images/lucy/lucy.svg'>
  <title>Developer Survey 2024</title>
  <style>"
  <> css
  <> "</style>
</head>
<body>
  <header>
    <div class='hero'>
      <div class='lucy-container'>
        <img class='lucy' src='https://gleam.run/images/lucy/lucy.svg'>
      </div>
      <h1>Gleam Developer Survey 2024</h1>
    </div>
    <img class='waves' src='https://gleam.run/images/waves.svg'>
  </header>
  <main>
"

const html_foot = "
  </main>
  <footer>
    This website is written in Gleam.
    <a href='https://github.com/gleam-lang/developer-survey'>View the source
    code</a>.
  </footer>
</body>
</html>
"

const html_form = html_head
  <> "
<p>
  All questions are optional, so fill in as much or as little as you like. If
  you have any question or problems please share them in
  <a href='https://discord.gg/Fm8Pwmy'>the Gleam Discord server</a>.
</p>
<p>
  Do share this survey with your Gleamy friends!
</p>

<form method='post'>
  <fieldset>
    <legend>What country do you live in?</legend>
    <input type='text' list='countries' name='country'>
  </fieldset>

  <fieldset>
    <legend>What's your job role?</legend>
    <input type='text' list='job-roles' name='job-role'>
  </fieldset>

  <fieldset>
    <legend>How many years of professional programming experience do you have?</legend>
    <input name='professional-experience' type='number' min=0 max=70>
  </fieldset>

  <fieldset>
    <legend>How large is your organisation?</legend>
    <select name='organisation-size'>
      <option value=''></option>
      <option value='No organisation'>Not part of any organisation</option>
      <option value='1 to 10'>1 to 10 people</option>
      <option value='11 to 50'>11 to 50 people</option>
      <option value='51 to 100'>51 to 100 people</option>
      <option value='101 to 500'>101 to 500 people</option>
      <option value='501 to 2000'>501 to 2000 people</option>
      <option value='More than 2001'>More than 2001 people</option>
    </select>
  </fieldset>

  <fieldset>
    <legend>What other languages do you use?</legend>
    <input type='text' list='languages' name='other-languages'>
    <button type='button' data-add-another-input>Add another</button>
  </fieldset>

  <fieldset>
    <legend>What operating systems do you use in development?</legend>
    <div class='columns'>
      <label><input type='checkbox' name='development-os' value='Android'>Android</label>
      <label><input type='checkbox' name='development-os' value='FreeBSD'>FreeBSD</label>
      <label><input type='checkbox' name='development-os' value='Linux'>Linux</label>
      <label><input type='checkbox' name='development-os' value='OpenBSD'>OpenBSD</label>
      <label><input type='checkbox' name='development-os' value='Windows'>Windows</label>
      <label><input type='checkbox' name='development-os' value='iOS'>iOS</label>
      <label><input type='checkbox' name='development-os' value='macOS'>macOS</label>
      <label><input type='checkbox' data-other-option='development-os'>Other</label>
    </div>
    <div data-show-if='[data-other-option=development-os]:checked'>
      <input type='text' name='development-os'>
      <button type='button' data-add-another-input>Add another</button>
    </div>
  </fieldset>

  <fieldset>
    <legend>What operating systems do you use in production?</legend>
    <div class='columns'>
      <label><input type='checkbox' name='production-os' value='Android'>Android</label>
      <label><input type='checkbox' name='production-os' value='FreeBSD'>FreeBSD</label>
      <label><input type='checkbox' name='production-os' value='Linux'>Linux</label>
      <label><input type='checkbox' name='production-os' value='OpenBSD'>OpenBSD</label>
      <label><input type='checkbox' name='production-os' value='Windows'>Windows</label>
      <label><input type='checkbox' name='production-os' value='iOS'>iOS</label>
      <label><input type='checkbox' name='production-os' value='macOS'>macOS</label>
      <label><input type='checkbox' data-other-option='production-os'>Other</label>
    </div>
    <div data-show-if='[data-other-option=production-os]:checked'>
      <input type='text' name='production-os'>
      <button type='button' data-add-another-input>Add another</button>
    </div>
  </fieldset>

  <fieldset>
    <legend>Have you used Gleam?</legend>
    <label><input type='radio' name='gleam-user' value='true'>Yes</label>
    <label><input type='radio' name='gleam-user' value='false'>No</label>
  </fieldset>

  <section data-show-if='[name=gleam-user][value=true]:checked'>
    <fieldset>
      <legend>How many years of Gleam programming experience do you have?</legend>
      <input name='gleam-experience' type='number' min=0 max=8>
    </fieldset>

    <fieldset>
      <legend>What Gleam compilation targets do you use?</legend>
      <label><input type='checkbox' name='targets' value='erlang'>Erlang</label>
      <label><input type='checkbox' name='targets' value='javascript'>JavaScript</label>
      <label><input type='checkbox' name='targets' value='unsure'>Unsure</label>
    </fieldset>

    <fieldset>
      <legend>What do you write in Gleam?</legend>
      <label><input type='checkbox' name='projects' value='applications'>Applications</label>
      <label><input type='checkbox' name='projects' value='libraries'>Libraries</label>
    </fieldset>

    <fieldset>
      <legend>What runtimes do you use?</legend>
      <div class='columns'>
        <label><input type='checkbox' name='runtimes' value='beam'>BEAM Erlang VM</label>
        <label><input type='checkbox' name='runtimes' value='atomvm'>AtomVM</label>
        <label><input type='checkbox' name='runtimes' value='web-browsers'>Web browsers</label>
        <label><input type='checkbox' name='runtimes' value='nodejs'>NodeJS</label>
        <label><input type='checkbox' name='runtimes' value='deno'>Deno</label>
        <label><input type='checkbox' name='runtimes' value='bun'>Bun</label>
        <label><input type='checkbox' name='runtimes' value='unsure'>Unsure</label>
        <label><input type='checkbox' data-other-option='runtimes'>Other</label>
      </div>
      <div data-show-if='[data-other-option=runtimes]:checked'>
        <input type='text' name='production-os'>
        <button type='button' data-add-another-input>Add another</button>
      </div>
    </fieldset>

    <fieldset>
      <legend>Do you use Gleam for open source?</legend>
      <label><input type='radio' name='gleam-open-source' value='true'>Yes</label>
      <label><input type='radio' name='gleam-open-source' value='false'>No</label>
    </fieldset>

    <fieldset>
      <legend>Do you use Gleam in production?</legend>
      <label><input type='radio' name='gleam-in-production' value='true'>Yes</label>
      <label><input type='radio' name='gleam-in-production' value='false'>No</label>
    </fieldset>

    <fieldset data-show-if='[name=gleam-in-production][value=true]:checked'>
      <legend>What is your organisation's name?</legend>
      <input type='text' name='organisation-name'>
    </fieldset>
  </section>

  <fieldset>
    <legend>Where do you get your Gleam news?</legend>
    <input type='text' list='news-sources' name='news-sources'>
    <button type='button' data-add-another-input>Add another</button>
  </fieldset>

  <fieldset>
    <legend>Do you sponsor Gleam?</legend>
    <label><input type='radio' name='individual-sponsor' value='true'>Yes</label>
    <label><input type='radio' name='individual-sponsor' value='false'>No</label>
    <p>
      Gleam has no corporate owner or other funding source. I rely on the the
      kind support of Gleam's sponsors to pay my bills and to support language
      development.
    </p>
    <p data-show-if='[name=individual-sponsor][value=true]:checked'>
      Thank you so much! 💜
    </p>
  </fieldset>

  <fieldset data-show-if='[name=organisation-size] option:not([value=\"\"]):not([value=\"No organisation\"]):checked'>
    <legend>Does your organisation sponsor Gleam?</legend>
    <label><input type='radio' name='organisation-sponsor' value='true'>Yes</label>
    <label><input type='radio' name='organisation-sponsor' value='false'>No</label>
    <p data-show-if='[name=organisation-sponsor][value=true]:checked'>
      Thank you so much! 💜
    </p>
  </fieldset>

  <fieldset data-show-if='[name=individual-sponsor][value=false]:checked, [name=organisation-sponsor][value=false]:checked'>
    <legend>What might make you consider sponsoring?</legend>
    <textarea name='sponsor-motivation'></textarea>
  </fieldset>

  <fieldset>
    <legend>What do you like about Gleam?</legend>
    <textarea name='likes'></textarea>
  </fieldset>

  <fieldset>
    <legend>What would you like see the Gleam team work on in 2025?</legend>
    <textarea name='improvements'></textarea>
  </fieldset>

  <fieldset>
    <legend>Anything else you'd like to say?</legend>
    <textarea name='anything-else'></textarea>
  </fieldset>

  <input type='submit' value='Submit'>
</form>

<script type='module'>
  for (const element of document.querySelectorAll('[data-show-if]')) {
    const handle = () => {
      if (document.querySelector(element.dataset.showIf)) {
        element.style.display = 'block';
      } else {
        element.style.display = 'none';
      }
    };
    element.closest('form').addEventListener('change', handle)
    handle();
  }

  for (const element of document.querySelectorAll('[data-add-another-input]')) {
    element.addEventListener('click', () => {
      const newInput = element.previousElementSibling.cloneNode();
      newInput.value = '';
      element.parentElement.insertBefore(newInput, element);
    });
  }

document.querySelector('form').addEventListener('keypress', event => {
  if (event.key === 'Enter') event.preventDefault();
});
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
  <option value=\"The Bahamas\"></option>
  <option value=\"Bahrain\"></option>
  <option value=\"Bangladesh\"></option>
  <option value=\"Barbados\"></option>
  <option value=\"Belarus\"></option>
  <option value=\"Belgium\"></option>
  <option value=\"Belize\"></option>
  <option value=\"Benin\"></option>
  <option value=\"Bermuda\"></option>
  <option value=\"Bhutan\"></option>
  <option value=\"Plurinational State of Bolivia\"></option>
  <option value=\"Bonaire, Sint Eustatius and Saba\"></option>
  <option value=\"Bosnia and Herzegovina\"></option>
  <option value=\"Botswana\"></option>
  <option value=\"Bouvet Island\"></option>
  <option value=\"Brazil\"></option>
  <option value=\"The British Indian Ocean Territory\"></option>
  <option value=\"Brunei Darussalam\"></option>
  <option value=\"Bulgaria\"></option>
  <option value=\"Burkina Faso\"></option>
  <option value=\"Burundi\"></option>
  <option value=\"Cabo Verde\"></option>
  <option value=\"Cambodia\"></option>
  <option value=\"Cameroon\"></option>
  <option value=\"Canada\"></option>
  <option value=\"The Cayman Islands\"></option>
  <option value=\"The Central African Republic\"></option>
  <option value=\"Chad\"></option>
  <option value=\"Chile\"></option>
  <option value=\"China\"></option>
  <option value=\"Christmas Island\"></option>
  <option value=\"The Cocos (Keeling) Islands\"></option>
  <option value=\"Colombia\"></option>
  <option value=\"The Comoros\"></option>
  <option value=\"The Democratic Republic of the Congo\"></option>
  <option value=\"The Congo\"></option>
  <option value=\"The Cook Islands\"></option>
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
  <option value=\"The Dominican Republic\"></option>
  <option value=\"Ecuador\"></option>
  <option value=\"Egypt\"></option>
  <option value=\"El Salvador\"></option>
  <option value=\"Equatorial Guinea\"></option>
  <option value=\"Eritrea\"></option>
  <option value=\"Estonia\"></option>
  <option value=\"Eswatini\"></option>
  <option value=\"Ethiopia\"></option>
  <option value=\"The Falkland Islands [Malvinas]\"></option>
  <option value=\"The Faroe Islands\"></option>
  <option value=\"Fiji\"></option>
  <option value=\"Finland\"></option>
  <option value=\"France\"></option>
  <option value=\"French Guiana\"></option>
  <option value=\"French Polynesia\"></option>
  <option value=\"The French Southern Territories\"></option>
  <option value=\"Gabon\"></option>
  <option value=\"The Gambia\"></option>
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
  <option value=\"The Holy See\"></option>
  <option value=\"Honduras\"></option>
  <option value=\"Hong Kong\"></option>
  <option value=\"Hungary\"></option>
  <option value=\"Iceland\"></option>
  <option value=\"India\"></option>
  <option value=\"Indonesia\"></option>
  <option value=\"Islamic Republic of Iran\"></option>
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
  <option value=\"The Democratic People's Republic of Korea\"></option>
  <option value=\"The Republic of Korea\"></option>
  <option value=\"Kuwait\"></option>
  <option value=\"Kyrgyzstan\"></option>
  <option value=\"The Lao People's Democratic Republic\"></option>
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
  <option value=\"The Marshall Islands\"></option>
  <option value=\"Martinique\"></option>
  <option value=\"Mauritania\"></option>
  <option value=\"Mauritius\"></option>
  <option value=\"Mayotte\"></option>
  <option value=\"Mexico\"></option>
  <option value=\"Federated States of Micronesia\"></option>
  <option value=\"The Republic of Moldova\"></option>
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
  <option value=\"The Netherlands\"></option>
  <option value=\"New Caledonia\"></option>
  <option value=\"New Zealand\"></option>
  <option value=\"Nicaragua\"></option>
  <option value=\"The Niger\"></option>
  <option value=\"Nigeria\"></option>
  <option value=\"Niue\"></option>
  <option value=\"Norfolk Island\"></option>
  <option value=\"The Northern Mariana Islands\"></option>
  <option value=\"Norway\"></option>
  <option value=\"Oman\"></option>
  <option value=\"Pakistan\"></option>
  <option value=\"Palau\"></option>
  <option value=\"Palestine, State of\"></option>
  <option value=\"Panama\"></option>
  <option value=\"Papua New Guinea\"></option>
  <option value=\"Paraguay\"></option>
  <option value=\"Peru\"></option>
  <option value=\"The Philippines\"></option>
  <option value=\"Pitcairn\"></option>
  <option value=\"Poland\"></option>
  <option value=\"Portugal\"></option>
  <option value=\"Puerto Rico\"></option>
  <option value=\"Qatar\"></option>
  <option value=\"Republic of North Macedonia\"></option>
  <option value=\"Romania\"></option>
  <option value=\"The Russian Federation\"></option>
  <option value=\"Rwanda\"></option>
  <option value=\"Réunion\"></option>
  <option value=\"Saint Barthélemy\"></option>
  <option value=\"Saint Helena, Ascension and Tristan da Cunha\"></option>
  <option value=\"Saint Kitts and Nevis\"></option>
  <option value=\"Saint Lucia\"></option>
  <option value=\"French part Saint Martin\"></option>
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
  <option value=\"Dutch part Sint Maarten\"></option>
  <option value=\"Slovakia\"></option>
  <option value=\"Slovenia\"></option>
  <option value=\"Solomon Islands\"></option>
  <option value=\"Somalia\"></option>
  <option value=\"South Africa\"></option>
  <option value=\"South Georgia and the South Sandwich Islands\"></option>
  <option value=\"South Sudan\"></option>
  <option value=\"Spain\"></option>
  <option value=\"Sri Lanka\"></option>
  <option value=\"The Sudan\"></option>
  <option value=\"Suriname\"></option>
  <option value=\"Svalbard and Jan Mayen\"></option>
  <option value=\"Sweden\"></option>
  <option value=\"Switzerland\"></option>
  <option value=\"Syrian Arab Republic\"></option>
  <option value=\"Province of China Taiwan\"></option>
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
  <option value=\"The Turks and Caicos Islands\"></option>
  <option value=\"Tuvalu\"></option>
  <option value=\"Uganda\"></option>
  <option value=\"Ukraine\"></option>
  <option value=\"The United Arab Emirates\"></option>
  <option value=\"The United Kingdom of Great Britain and Northern Ireland\"></option>
  <option value=\"The United States Minor Outlying Islands\"></option>
  <option value=\"The United States of America\"></option>
  <option value=\"Uruguay\"></option>
  <option value=\"Uzbekistan\"></option>
  <option value=\"Vanuatu\"></option>
  <option value=\"Bolivarian Republic of Venezuela\"></option>
  <option value=\"Viet Nam\"></option>
  <option value=\"British Virgin Islands\"></option>
  <option value=\"U.S. Virgin Islands\"></option>
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

<datalist id='news-sources'>
  <option value='Bluesky'></option>
  <option value='Elixir Forum'></option>
  <option value='Erlang Forums'></option>
  <option value='GitHub'></option>
  <option value='Gleam Weekly'></option>
  <option value='Hacker News'></option>
  <option value='The Fediverse'></option>
  <option value='The Gleam Discord Server'></option>
  <option value='Twitter @gleamlang'></option>
  <option value='Twitter @louispilfold'></option>
  <option value='Twitter'></option>
  <option value='gleam.run'></option>
  <option value='lobste.rs'></option>
  <option value='reddit.com'></option>
  <option value='reddit.com/r/elixir'></option>
  <option value='reddit.com/r/gleamlang'></option>
</datalist>

<datalist id='job-roles'>
  <option value='Agile Coach'></option>
  <option value='CEO'></option>
  <option value='CTO'></option>
  <option value='Consultant'></option>
  <option value='Data engineer'></option>
  <option value='Developer Relations'></option>
  <option value='Director of Engineering'></option>
  <option value='Engineering Manager'></option>
  <option value='Head of Engineering'></option>
  <option value='Infrastructure engineer'></option>
  <option value='Intern'></option>
  <option value='Lecturer'></option>
  <option value='Maker'></option>
  <option value='Managing Director'></option>
  <option value='Open Source Engineer'></option>
  <option value='Other'></option>
  <option value='Principal Engineer'></option>
  <option value='Researcher'></option>
  <option value='Scrum Master'></option>
  <option value='Security Manager'></option>
  <option value='Security engineer'></option>
  <option value='Senior Software Engineer'></option>
  <option value='Software Architect'></option>
  <option value='Software Engineer'></option>
  <option value='Staff Engineer'></option>
  <option value='Start-up founder'></option>
  <option value='Student'></option>
  <option value='Teaching Assistant'></option>
  <option value='Tech Lead'></option>
</datalist>
"
  <> html_foot

const html_thanks = html_head
  <> "
<p>
  Thank you! The results will be shared before the end of the year on <a
  href='https://gleam.run/news/'>the Gleam website</a>.
</p>
<p>
  Please share this survey with your Gleamy friends.
</p>
"
  <> html_foot

const cookie_name = "gleam-developer-survey-submitted"

const css = "
@font-face {
  font-family: 'Lexend';
  font-display: swap;
  font-weight: 400;
  src: url('https://gleam.run/fonts/Lexend.woff2') format('woff2');
}

@font-face {
  font-family: 'Lexend';
  font-display: swap;
  font-weight: 700;
  src: url('https://gleam.run/fonts/Lexend-700.woff2') format('woff2');
}

@font-face {
  font-family: 'Outfit';
  font-display: swap;
  src: url('https://gleam.run/fonts/Outfit.woff') format('woff');
}

:root {
  --font-family-normal: 'Outfit', sans-serif;
  --font-family-title: 'Lexend', sans-serif;
  --color-underwater-blue: #292d3e;
  --color-aged-plastic-yellow: #fffbe8;
  --color-white: #fefefc;
  --color-faff-pink: #ffaff3;
  --color-blacker: #151515;
  --width-content: 640px;

  --waves-height: 100px;
  --waves-width: 1200px;

  --font-weight-normal: 400;
  --font-weight-title-bold: 700;

  --font-size-normal: 18px;
  --gap-1: 10px;
  --gap-2: calc(var(--gap-1) * 2);
  --gap-3: calc(var(--gap-1) * 3);
  --gap-4: calc(var(--gap-1) * 4);
}

*, *::before, *::after {
  box-sizing: border-box;
}

* {
  margin: 0;
}

body {
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}

header {
  width: 100%;
  padding-top: var(--gap-2);
  background-color: var(--color-aged-plastic-yellow);
  color: var(--color-blacker);
  text-align: center;
  overflow: hidden;
}

img, picture, video, canvas, svg {
  display: block;
}

input, button, textarea, select {
  font: inherit;
}

p, h1, h2, h3, h4, h5, h6 {
  overflow-wrap: break-word;
}

p {
  text-wrap: pretty;
  margin: 8 0;
}
h1, h2, h3, h4, h5, h6 {
  text-wrap: balance;
}

#root, #__next {
  isolation: isolate;
}

[data-show-if] {
  display: none;
}

body {
  background-color: var(--color-underwater-blue);
  color: var(--color-white);
  font-family: var(--font-family-normal);
  font-size: var(--font-size-normal);
}

main {
  max-width: 100%;
  width: var(--width-content);
  margin: 0 auto;
  padding: var(--gap-2);
}

.waves {
  position: relative;
  --overlap: 5px;
  bottom: calc(var(--overlap) * -1);
  height: var(--waves-height);
  width: calc(max(100%, var(--waves-width)) + calc(var(--overlap) * 2));
  left: min(0px, calc(calc(100vw - var(--waves-width)) * 0.2));
}

h1 {
  font-family: var(--font-family-title);
  font-weight: var(--font-weight-title-bold);
}

h2,
h3,
h4,
h5,
h6 {
  font-family: var(--font-family-title);
  font-weight: var(--font-weight-normal);
}

a:visited,
a {
  color: var(--color-white);
  text-decoration-color: var(--color-faff-pink);
}

fieldset {
  padding: 0;
  border: 0;
  margin: var(--gap-2) 0;
}

select,
textarea,
input:not([type='checkbox']):not([type='radio']) {
  display: block;
  width: 100%;
  margin: var(--gap-1) 0;
  padding: 4px var(--gap-1);
  border-radius: 1px;
  border: none;
}

select {
  appearance: none;
}

input[type='checkbox'],
input[type='radio'] {
  margin-right: var(--gap-1);
}

label {
  display: block;
}

legend {
  font-size: 110%;
}

.columns {
  column-count: 2;
}

h1 {
  margin: var(--gap-2) 0;
}

form {
  margin: var(--gap-4) 0;
}

footer {
  margin-top: var(--gap-4);
  text-align: center;
  font-size: 80%;
}

.hero {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
}

.lucy {
  margin: 0;
  max-width: 200px;
  transition: transform 0.2s ease;
}

.lucy-container:hover .lucy {
  content: url('https://gleam.run/images/lucy/lucyhappy.svg');
  transform: rotate(23deg);
}
"
