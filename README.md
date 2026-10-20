# %shelf

A public web page that lists the apps your Urbit ship publishes, so anyone can
install them on their own ship.

The page shows your ship's `%treaty` alliance: your own published desks plus
any desks you republish from other ships. Each app has an Install button that
opens it in the visitor's own Landscape, and the Dojo `|install` command as a
fallback. The page follows the visitor's light or dark preference. It has no
JavaScript except for the Copy buttons.

%shelf answers on exactly one path, `/shelf`. Run it behind a reverse proxy
that serves it at the root of a dedicated domain (see
[Serving it on its own domain](#serving-it-on-its-own-domain)). All of the
page's links point at `/`.

## Requirements

- Kernel `[%zuse 408]`.
- `%landscape`, which provides `%treaty`. Fresh ships have it.

## Install

Build the desk with Nix. `result` is then the desk folder:

```sh
nix build github:iko-soy/shelf
```

From a checkout, `nix build` does the same, or you can use `desk/` directly.

Then, with your ship running:

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
own page, where others can install it.

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
  (`/?install=…`) reaches the ship intact.
- `Forwarded` tells Eyre the visitor came over HTTPS. Eyre trusts it only
  from `127.0.0.1`, hence the IP instead of `localhost`. Without it, a ship
  that also serves its own TLS redirects every proxied request to its HTTPS
  port. It also lets %shelf mark its cookie `Secure`.
- Caddy passes the original `Host` header through. %shelf compares it with
  `Origin` or `Referer` when a browser doesn't send `Sec-Fetch-Site`. With
  another proxy, pass `Host` through (nginx: `proxy_set_header Host $host;`)
  and send `Forwarded` (or `X-Forwarded-Proto`) the same way.
- Your ship's own domain is unaffected: `/` still goes to Landscape.

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
  check for `http(s)` before using them.
- Entries are sorted like the page. Key order within an object is not fixed.
- JSON wins when the header ranks `application/json` above `text/html`. When
  the two rank equally, the more specific match wins, so
  `application/json, */*` gets JSON. A full tie, a bare `*/*` or a missing
  header gets HTML.
- The response has `Access-Control-Allow-Origin: *`, varies on `Accept` and
  `Origin`, and is `private, max-age=60`. It is private because Eyre attaches
  its session cookie to every response, and on your own logged-in requests
  that cookie is your login token.

## How installing works for a visitor

1. **Install** opens a panel under the app. It asks for the visitor's ship
   URL (for example `sampel-palnet.tlon.network`) and shows the Dojo command.
2. The form is POSTed. %shelf checks the URL and keeps only its scheme, host
   and port. It remembers that origin in a cookie for a year, then redirects
   to
   `<ship>/apps/landscape/search/direct/apps/~publisher/desk`. That is
   Landscape's own "Get App" dialog. The visitor's ship fetches the app's
   details directly from the publisher.
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
- On the page, image and website URLs from dockets are used only if they are
  `http(s)`. Dockets can come from other ships.

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

## Development

The desk is self-contained. `desk/` holds everything Clay needs:

| Path | What |
|---|---|
| `desk.docket-0` | What Landscape shows: title, description, color, version, website, license |
| `app/shelf.hoon` | The agent: Eyre binding, routing, scries, responses |
| `lib/shelf.hoon` | Pure helpers and the page (Sail) |
| `sur/shelf.hoon`, `mar/shelf/action.hoon`, `gen/shelf/` | The `head`/`body` settings |
| `web/shelf.css`, `web/copy.js` | Inlined into the page at build time with `/*` |
| `tests/lib/shelf.hoon` | Unit tests, including the rendered page |
| `lib/sigil.hoon`, `lib/sigil/symbols.hoon` | Vendored [sigil renderer](https://github.com/Fang-/suite) (MIT, ~paldev; shapes from `@urbit/sigil-js`, MIT, Tlon) |
| other `lib/`, `mar/`, `sur/` files | Copied unmodified from `%base` (urbit/urbit `5a187fe`) and `%landscape` (`sur/treaty`, `sur/docket`, `lib/docket`, `mar/docket-0`; tloncorp/landscape `46c6ed8`) |

`flake.nix` makes `nix build` produce the desk as `result`.

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
