<img src="desk/web/shelf-icon.svg" width="96" height="96" alt="Shelf logo">

# %shelf

A public web page that lists the apps your Urbit ship publishes, so anyone can
install them on their own ship.

The page shows your ship's `%treaty` alliance: your own published desks plus
any desks you republish from other ships. Each app has an Install button that
opens it in the visitor's own Landscape, and the Dojo `|install` command as a
fallback. The page follows the visitor's light or dark preference. It has no
JavaScript except for the Copy buttons. The same URL also returns the list as
JSON.

%shelf answers on exactly one path, `/shelf`. Run it behind a reverse proxy
that serves it at the root of a dedicated domain (see
[Serving it on its own domain](#serving-it-on-its-own-domain)). The page's
links and its install form all point at `/`.

## Requirements

- Kernel `[%zuse 408]`.
- `%landscape`, which provides `%treaty` and `%docket`. Fresh ships have it.
- Nix, for the one-command build. Without it, copy `desk/` from a checkout.

## Install

```sh
nix build github:iko-soy/shelf
```

`result` is now the desk folder (see [Building with Nix](#building-with-nix)).
Without Nix, use `desk/` from a checkout in its place. Then, with your ship
running:

```
~sampel-palnet:dojo> |new-desk %shelf
~sampel-palnet:dojo> |mount %shelf
```

```sh
cp -R result/* /path/to/pier/shelf/
chmod -R u+w /path/to/pier/shelf    # files from the Nix store are read-only
```

```
~sampel-palnet:dojo> |commit %shelf
~sampel-palnet:dojo> |install our %shelf
```

The page is now at `https://<your-ship>/shelf`, and Landscape shows a Shelf
tile that opens it. It is meant to be opened through your own domain, though:
on the ship's address the page renders, but its links lead to `/`, which
belongs to Landscape.

## Building with Nix

`flake.nix` has one output: `packages.<system>.default`, the desk. Building it
copies `desk/` into the Nix store; nothing is compiled, because Clay compiles
the Hoon on your ship when you commit the desk.

| Command | Builds |
|---|---|
| `nix build github:iko-soy/shelf` | the latest commit on the default branch |
| `nix build github:iko-soy/shelf/<commit>` | a specific commit |
| `nix build` | your checkout, from the repo root |

Each one leaves a `result` symlink to the desk in the store:

```
result/
├── desk.bill  desk.docket-0  sys.kelvin
├── app/  gen/  lib/  mar/  sur/  tests/
└── web/
```

- Files in the store are read-only, so `chmod -R u+w` the mount after copying
  them in: the ship has to be able to write to its own mount.
- `nix flake check --all-systems` checks the flake on every system it
  supports: `x86_64-linux`, `aarch64-linux` and `aarch64-darwin`. Plain
  `nix flake check` checks only your own. Current nixpkgs no longer supports
  Intel Macs.
- nixpkgs is only used for `runCommandLocal`. `nix flake update` moves its
  pin in `flake.lock`.
- From another flake, for example a NixOS config that sets up a ship, the desk
  is:

  ```nix
  inputs.shelf.url = "github:iko-soy/shelf";
  # …
  shelf.packages.${system}.default
  ```

## Update

Build and copy the desk into the mount again, as above, and run
`|commit %shelf`. Then check that `.^(cass:clay %cw /=shelf=)` moved: if the
new version doesn't build, Clay keeps the old one and logs nothing.

%shelf is installed from your own ship, so it gets no over-the-air updates.
After a kernel upgrade, Clay holds it until `desk/sys.kelvin` lists the new
`%zuse` version; update that file (or pull a release that has) and commit.
`+vats %shelf` shows whether it is running or held.

## Choose what's listed

%shelf lists your `%treaty` alliance. A desk needs a `desk.docket-0` file
before you can publish it.

- List one of your own desks with `:treaty|publish %my-app`, and remove it with
  `:treaty|unpublish %my-app`.
- To republish another ship's desk, follow the publisher with
  `:treaty|ally ~other-ship`, then add the desk with
  `:treaty|add-desk ~other-ship %app`. Remove it with
  `:treaty|remove-desk ~other-ship %app`, and stop following with
  `:treaty|unally ~other-ship`.

%shelf has a docket of its own, so `:treaty|publish %shelf` lists it on its
own page, where others can install it. The docket carries the app icon
inline, as a URL-encoded `data:` URL, so the icon shows in Landscape and on
other ships' pages with nothing to host.

A republished app appears once your ship has received its docket from the
publisher, which happens a few seconds after you ally them. Apps are sorted by
title. %shelf reads the alliance on every request, but browsers may show a
copy up to a minute old.

## Serving it on its own domain

Point a domain such as `apps.example.com` at a Caddy server that sends every
request to the ship's `/shelf`:

```caddyfile
apps.example.com {
	@other not path /
	redir @other /
	rewrite * /shelf
	reverse_proxy 127.0.0.1:8080 {
		header_up Forwarded "proto={scheme}"
	}
}
```

- `8080` is the ship's HTTP port.
- `redir` sends every path except `/` back to `/`, so nothing else on your
  ship can be reached through this domain.
- `rewrite` replaces only the path, so the query string the page relies on
  (`/?install=…`, `/?asset=…`) reaches the ship intact.
- `Forwarded` tells Eyre the visitor came over HTTPS. Eyre trusts it only
  from `127.0.0.1`, hence the IP instead of `localhost`. Without it, a ship
  that also serves its own TLS redirects every proxied request to its HTTPS
  port. It also lets %shelf mark its cookie `Secure`.
- Caddy passes the original `Host` header through. %shelf compares it with
  `Origin` or `Referer` when a browser doesn't send `Sec-Fetch-Site`. With
  another proxy, pass `Host` through (nginx: `proxy_set_header Host $host;`)
  and send `Forwarded` (or `X-Forwarded-Proto`) the same way.
- Your ship's own domain is unaffected: `/` still goes to Landscape.
- %shelf serves everything the page needs from the desk, at the same URL: the
  CSS and JavaScript inline, and the favicon at `/?asset=favicon.svg`. It
  also serves the app icon at `/?asset=shelf-icon.svg`, though the docket
  carries that inline. Nothing else needs to be reachable.

This config was tested with Caddy 2.11 in front of a fake ship.

## Analytics and other tags

You can add raw HTML to the end of the page's `<head>` and `<body>`, for
example an analytics snippet:

```
:shelf|head '<script defer data-domain="apps.example.com" src="https://plausible.io/js/script.js"></script>'
:shelf|body '<script async src="https://example.com/counter.js"></script>'
```

- The HTML goes into the page as-is, unescaped.
- Dojo takes the snippet on one line. Inside it, write a `'` as `\'`, a `\` as
  `\\`, and a newline (if you need one) as `\0a`.
- Clear a setting with `:shelf|head ''` or `:shelf|body ''`.
- Read the current values with `.^(@t %gx /=shelf=/head/noun)` and
  `.^(@t %gx /=shelf=/body/noun)`.
- Only the ship itself can change these settings.

## JSON

Ask for JSON with an `Accept` header, at the same URL:

```sh
curl -H 'Accept: application/json' https://apps.example.com/
```

```json
[{
  "ship": "~sampel-palnet", "desk": "harbor", "title": "Harbor",
  "info": "Every desk on your ship: its version, its source, its updates.",
  "color": "#24466f", "image": "https://…/harbor.svg", "version": "2.0.1",
  "website": "https://…", "license": "MIT", "hash": "0v…",
  "install": "|install ~sampel-palnet %harbor"
}]
```

- `image` is `null` when the docket has none, and `website` is `""`.
- `image` and `website` are the docket's values as they are. Dockets can come
  from other ships, and unlike the page, the JSON doesn't filter these, so
  check them before using them. `image` may also be an inline
  `data:image/…` URL.
- Text that isn't valid UTF-8 comes out with U+FFFD in its place, so the
  listing is always valid JSON.
- Entries are sorted like the page. Key order within an object is not fixed.
- JSON wins when the header ranks `application/json` above `text/html`. When
  the two rank equally, the more specific match wins, so
  `application/json, */*` gets JSON. A full tie, a bare `*/*` or a missing
  header gets HTML. Repeated `Accept` lines count as one list.
- The response has `Access-Control-Allow-Origin: *`, varies on `Accept` and
  `Origin`, and is `private, max-age=60`. It is private because Eyre attaches
  its session cookie to every response, and on your own logged-in requests
  that cookie is your login token.

## How installing works for a visitor

1. **Install** opens a panel under the app. It asks for the visitor's ship
   URL (for example `sampel-palnet.tlon.network`) and shows the Dojo command.
2. The form is POSTed. %shelf checks the URL and keeps only its scheme, host
   and port. It remembers that origin in a cookie for a year, then redirects
   to `<ship>/apps/landscape/search/direct/apps/~publisher/desk`. That is
   Landscape's own "Get App" dialog. The visitor's ship fetches the app's
   details directly from the publisher, and a visitor who isn't logged in
   lands there after their ship's login page.
3. On later visits, Install links straight there. The button reads
   `Install on ~sampel-palnet` when the URL's first label is a planet name
   (or a moon or comet), or any ship name on `arvo.network`, `tlon.network`
   or `startram.io`. Otherwise it reads `Install on your ship`: galaxy and
   star names double as ordinary words, like `dev.` or `master.`. A
   **Change ship** link in the header clears the cookie.

Guards:

- The ship URL is only saved and followed from a POST that comes from the page
  itself (checked with `Sec-Fetch-Site`, or else `Origin` or `Referer`
  against `Host`). Links and images can't POST, so nothing else, including a
  docket image URL pointing at your domain, can plant a URL in a visitor's
  cookie or bounce them elsewhere through your domain.
- Only apps actually on the shelf can be installed through the form.
- On the page, docket images are used only if they are `http(s)` or
  `data:image/…` URLs, and website links only if they are `http(s)`.
  Dockets can come from other ships.

## Traffic

Every request that arrives without a cookie makes Eyre start a guest session.
Crawlers, uptime monitors, `curl` and other sites fetching the JSON all do
this. Each session costs your ship about 0.2 KB of memory for 7 days, plus
about 0.3 KB of event log. A page view takes the ship about 50 ms with 10
apps, so requests start to queue above about 20 a second.

- If the page draws heavy bot traffic, rate-limit it in your proxy.
- Point uptime monitors at the proxy rather than the page.
- Analytics or consent tools that store JSON in cookies on this domain stop
  Eyre from reading its own session cookie, so every page view then starts a
  new session.
- For a cookie notice: besides %shelf's `shelf-ship` (the visitor's ship URL,
  one year), Eyre sets its own session cookie, `urbauth-~your-ship`, for 7
  days.

## Uninstalling

Gall gives an agent no chance to clean up, so Eyre keeps the `/shelf` binding
after %shelf stops. Until you remove it, `/shelf` answers 503 at once.

1. Remove the site from your reverse proxy first. Otherwise visitors get that
   503 page, or, once the binding is gone, an endless redirect loop between
   Landscape's login page and `/`.
2. `:docket|uninstall %shelf`, or Uninstall from the tile's menu in
   Landscape. This removes the tile and suspends the agent; a plain
   `|uninstall %shelf` would leave a suspended tile behind. Your `head`/`body`
   HTML is kept, and `|install our %shelf` brings the page straight back.
3. To delete that state too: `|nuke %shelf, =desk &` (answer `y`).
4. Optionally, free the path. Only the binding's owner can remove it, so take
   it over from the dojo, then remove it:

   ```
   |pass [%e %connect [~ /shelf] %docket]
   |pass [%e %disconnect [~ /shelf]]
   ```

   Installing %shelf again binds `/shelf` again. %shelf re-binds every time
   it loads, so it also restores the binding if someone removed it by hand.

## Changes from the design handoffs

%shelf follows two design handoffs: the page itself (layout, copy, behaviour,
JSON, a skeleton agent) and a later icon update. Rendered with the mock's sample
data, the page matches the design mock pixel for pixel in light and dark mode,
apart from the icons and names. Everything below differs from the handoffs,
and why.

**Serving**
- **One path, `/shelf`, instead of `/`.** On most ships Landscape's `%docket`
  owns `/`, and Eyre doesn't refuse a second claim: it silently hands `/`
  over, which would take away the owner's login page. A dedicated domain
  mapped onto `/shelf` gives visitors a clean root URL instead.
- **One URL for everything.** Because only `/` reaches the ship through that
  domain, the CSS and JavaScript are inlined (not `/shelf.css`, `/copy.js`),
  the icons are at `/?asset=…` (not `/favicon.svg`, `/shelf-icon.svg`), the
  install form posts to `/` (not `/install`), and Change ship is `/?forget`
  (not `/forget`). Other paths are the proxy's job; the ship answers them
  with 404.
- **JSON by `Accept` header at the same URL, not `/apps.json`, and
  `private`.** The single URL rules out `/apps.json`, and `public` caching
  could hand an owner's login cookie to a shared cache.
- **HTML varies on `Cookie` as well as `Accept`.** Otherwise a browser shows
  its cached copy for up to a minute after Change ship or a save.
- **Bodies go out in 16 KiB pieces**, because a single large response gets
  quadratically slower on its way out of the ship.

**Installing**
- **The install form is a POST, accepted only from the page itself, and only
  for apps on the shelf.** A GET could be triggered by a link or by another
  publisher's docket image, planting a phishing URL in visitors' cookies.
- **Deep link:** `<ship>/apps/landscape/search/direct/apps/~pub/desk`,
  Landscape's own "show install" route, tested end to end. The handoff's
  `…/leap/search/…` also works, but only through a redirect.
- **Saved ship URLs keep only scheme, host and port**, so a pasted
  `…/apps/groups` doesn't break the deep link. `localhost` and `127.*`
  default to `http://`, and ports must be 1–65535.
- **The cookie holds the URL as is (not URL-encoded), `HttpOnly`, and gets
  `Secure` when the visitor came over HTTPS**, as `Forwarded` or
  `X-Forwarded-Proto` says behind a proxy. The normalized URL only contains
  cookie-safe characters.
- **"Install on ~ship" needs a planet or longer name, or a known ship host.**
  The handoff's rule (any first DNS label that parses as an `@p`) turned
  `dev.example.com` into "Install on ~dev".
- **Returning visitors see "Installs open on ~ship. Change ship"** in the
  masthead, a muted link that clears the cookie. The handoff left this open.

**Reading the alliance**
- **Own desks' treaties are built from Clay**, from each desk's
  `desk.docket-0`, as `%treaty` does. `%treaty`'s `/treaty/<ship>/<desk>`
  scry only covers other ships' desks and crashes for your own.
- **Only scries that can't fail.** The handoff wrapped scries in `mule`, but
  inside an agent `mule` can't catch a failed scry: the request just fails.
- **Visitors arrive under an Eyre guest identity**, so the owner check
  applies only to the settings pokes. Checking every request would 500 for
  all visitors.
- **Docket text from other ships is handled defensively:** images only
  `http(s)` or `data:image/…`, links only `http(s)`, invalid UTF-8 replaced
  in the JSON, and a title that starts with a control character still
  renders.

**Page**
- **Header and rows share one grid (CSS subgrid)**, so columns stay aligned
  when Install labels get wider for a saved ship.
- **Narrow screens:** with a saved ship the stacked layout starts at 1040px
  instead of 860px, and the install button's text wraps; the URL field gets
  its own line; long words wrap instead of overflowing.
- **Keyboard focus inside a row tints it**, as the handoff's interaction table
  says (its CSS only did this on hover).
- **"1 app"**, not "1 apps".
- **Republished apps say "from ~publisher"**, not "by ~publisher".
- **The sigil is drawn in Hoon** by a vendored renderer, in `currentColor` on
  `var(--ink)` so it inverts with the theme, at sigil-js's 56px geometry.
  Moons and comets get the plain square, as in Landscape.
- **New: owner-set raw HTML in `<head>` and `<body>`**, for analytics.

**Icons and docket** (the icon update)
- **The docket's `image` is the icon inline, as a URL-encoded `data:` URL**,
  instead of an absolute URL on the ship, which would need filling in per
  ship and would break wherever that ship can't be reached.
- **The tile opens `/shelf`** (`site+/shelf`, not `site+/`), and the docket's
  website is this repo.
- **The docket's description drops "with one-click install"**: first-time
  visitors enter their ship's URL before the Install button takes them there.
- **`mar/svg` is the upstream mark from `%base`**, not the handoff's new one.
- **Icons are served `private`** for the same login-cookie reason as the
  JSON.

**Other**
- **Kernel `[%zuse 408]`**, the current release, replacing the handoff's
  placeholder 409.

## Development

The desk is self-contained. `desk/` holds everything Clay needs:

| Path | What |
|---|---|
| `desk.docket-0` | What Landscape shows: title, description, color, icon, version, website, license. Its `image` is `web/shelf-icon.svg` URL-encoded; a test checks they match |
| `app/shelf.hoon` | The agent: Eyre binding, routing, scries, responses |
| `lib/shelf.hoon` | Pure helpers and the page (Sail) |
| `sur/shelf.hoon`, `mar/shelf/action.hoon`, `gen/shelf/` | The `head`/`body` settings |
| `web/shelf.css`, `web/copy.js` | Inlined into the page at build time with `/*` |
| `web/shelf-icon.svg`, `web/favicon.svg` | The app icon (also inlined in the docket) and the favicon, served at `?asset=` |
| `tests/lib/shelf.hoon` | Unit tests, including the rendered page |
| `lib/sigil.hoon`, `lib/sigil/symbols.hoon` | Vendored [sigil renderer](https://github.com/Fang-/suite) (MIT, ~paldev; shapes from `@urbit/sigil-js`, MIT, Tlon) |
| other `lib/`, `mar/`, `sur/` files | Copied unmodified from `%base` (urbit/urbit `5a187fe`, including `mar/svg`) and `%landscape` (`sur/treaty`, `sur/docket`, `lib/docket`, `mar/docket-0`; tloncorp/landscape `46c6ed8`) |

Outside the desk, `flake.nix` and `flake.lock` define the Nix build (see
[Building with Nix](#building-with-nix)).

Run the tests on a ship with the desk installed:

```
-test /=shelf=/tests ~
```

Some details that are easy to get wrong:

- **Public requests come from guests.** Eyre gives unauthenticated visitors a
  guest identity, so `src.bowl` isn't your ship. Owner checks apply only to
  the settings pokes.
- **A failed scry can't be caught.** Inside an agent, `mule` does not catch a
  scry that fails: the whole request fails. %shelf only makes scries that
  can't fail.
- **Own treaties aren't scryable.** `%treaty` doesn't expose your own desks'
  treaties, so %shelf builds them from each desk's `desk.docket-0` the same
  way `%treaty` does.
- **Clay can refuse a commit silently.** It refuses commits that would stop a
  running agent from building, and logs nothing. After `|commit`, check that
  `.^(cass:clay %cw /=shelf=)` moved.

## License

MIT; see [LICENSE](LICENSE). The vendored files keep their own notices:
`lib/sigil.hoon` and `lib/sigil/symbols.hoon` are MIT (Fang; shapes from
`@urbit/sigil-js`, Tlon), and the files from `%base` and `%landscape` come
from urbit/urbit (MIT) and tloncorp/landscape.
