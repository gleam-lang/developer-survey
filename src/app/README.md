# Gleam Developer Survey – *✨ Frontend Edition ✨*

The frontend for the Gleam Developer Survey: built with 💕 using
[lustre](https://hexdocs.pm/lustre) and [react](https://reactjs.org).

## Quick start

```sh
npm install
npm start
```

## `chokidar`, `concurrently`, `parcel`, ...?

If you're coming from the strictly BEAM side of Gleam, you might be wondering
what all these dependencies are for. Here's a quick rundown of what they are and
why I've included them:

* `chokidar` is a file watcher that is used to watch for changes in our Gleam
    source and trigger a recompilation when that happens.
* `concurrently` is a tool that allows us to run multiple commands at the same
    time. The important bit is the `--kill-others` flag that will send a SIGTERM
    to all the other concurrent processes when one receives it. We use this to
    run the `chokidar` watcher and `parcel` at the same time. I expect there is
    a perfectly reasonable way to do this without a third-party dependency, but
    I'm shit at terminal things... PRs welcome 😇.
* `parcel` is a bundler and dev server for JavaScript apps. These days I tend to
    prefer something different, but it's still pretty quick and easy to get going
    with parcel so it's fine for here. The included dev server has hot module
    reloading, which when combined with our chokidar watcher, means that we can
    make changes to our Gleam code and see them reflected in the browser in
    real-time.

    `parcel` will also handle bundling for production, including tree-shaking
    which is particularly useful for Gleam apps because the Gleam compiler
    doesn't do this for us.

## What's that `alias` field in `package.json`?

Parcel let's us override it's usual module resolution algorithm by providing
our own aliases to paths and modules. This is particularly useful for Gleam
because at the moment Gleam builds to `./build/dev/app/dist/...` and remembering
that path is a pain 😅.

Instead, we alias our `main.gleam` module to `app` and then we can import it
simply as

```js
import * as App from 'app'
```

> ❗️ It's really important that you don't move or rename `main.gleam`, or if you
> have to, remember to update the alias in `package.json`!

The second alias is nifty. Gleam has some support for interfacing with JavaScript
code through `external` declarations, but the Gleam compiler only copies
*top-level* JavaScript into the build directory. This means if you to organise
your FFI code somewhere else, you can't!

I'm a chronic organiser, so I want to keep any FFI code in a separate directory
rather than floating around at the top-level, so we alias `ffi` to point to
`./src/ffi` and then let parcel do it's thing and resolve that for any modules
that import FFI code.

In `src/app/route.gleam`, for example, we have:

```gleam
external fn on_hash_change(fn(String) -> any) -> Nil =
  "ffi/window.mjs" "on_hash_change"
```

Much nicer!
