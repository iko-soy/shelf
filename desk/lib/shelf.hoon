::  shelf: helpers for the %shelf agent
::
::    Pure functions only (no bowl, no scries), so /tests/lib/shelf
::    can cover them.
::
/-  treaty
/+  sigil
|%
::  +sigil-svg: a ship's sigil for the masthead's 56px box
::
::    lib/sigil paints the glyph in fg, and the details that cut into
::    it (lines, rings, dots) in bg, over a bg rect. fg is currentColor
::    (.sigil sets color: var(--bg)) and bg is var(--ink), the box's
::    background, so the sigil inverts with the theme. The geometry is
::    reset to @urbit/sigil-js's default, which the design used: glyph
::    at 75% of the box, 0.65625px lines (lib/sigil's strokes don't
::    scale, so stroke-width is in CSS px).
::
::    Moons and comets get ~: sigil-js draws nothing for them, and
::    neither do Landscape or Tlon.
::
++  sigil-svg
  |=  who=ship
  ^-  (unit manx)
  =/  tr=(unit tape)
    ?+  (clan:title who)  ~
      %czar  `"translate(40 40) scale(0.375)"
      %king  `"translate(16 40) scale(0.375)"
      %duke  `"translate(16 16) scale(0.375)"
    ==
  ?~  tr  ~
  =/  svg=manx
    %.  who
    %_  sigil
      size  56
      fg    "currentColor"
      bg    "var(--ink)"
    ==
  :-  ~
  %-  sigil-paint
  %_    svg
      c
    %+  turn  c.svg
    |=  m=manx
    ?.  =(%g n.g.m)  m
    =-  m(a.g [[%transform u.tr] [%stroke-width "0.65625"] -])
    (skip a.g.m |=([n=mane *] |(=(%transform n) =(%stroke-width n))))
  ==
::
::  +sigil-paint: drop lib/sigil's inline px size, which would beat the
::  page CSS, and move fill/stroke="var(--ink)" into style="", where
::  var() is plain CSS rather than an attribute value.
::
++  sigil-paint
  |=  m=manx
  ^-  manx
  =/  ink=tape  "var(--ink)"
  =/  css=(list tape)
    %+  murn  a.g.m
    |=  [n=mane v=tape]
    ?.  &(=(ink v) |(=(%fill n) =(%stroke n)))  ~
    `"{?:(=(%fill n) "fill" "stroke")}:{v}"
  =/  rest=mart
    %+  skip  a.g.m
    |=  [n=mane v=tape]
    |(=(%style n) &(=(ink v) |(=(%fill n) =(%stroke n))))
  %_  m
    a.g  ?~(css rest [[%style (zing (join ";" css))] rest])
    c    (turn c.m sigil-paint)
  ==
::
::  the cookie that remembers a visitor's ship URL
::
++  cookie-name  'shelf-ship'
::
::  +ship-cookie: Set-Cookie value remembering a ship URL for a year
::
::    The URL comes from +normalize-url, so it is all cookie-safe
::    characters and needs no encoding.
::
++  ship-cookie
  |=  [url=@t secure=?]
  ^-  @t
  %-  crip
  %+  weld  "{(trip cookie-name)}={(trip url)}; Path=/; Max-Age=31536000"
  ?:(secure "; SameSite=Lax; HttpOnly; Secure" "; SameSite=Lax; HttpOnly")
::
::  +forget-cookie: Set-Cookie value that clears the saved ship URL
::
++  forget-cookie
  |=  secure=?
  ^-  @t
  %-  crip
  %+  weld  "{(trip cookie-name)}=; Path=/; Max-Age=0"
  ?:(secure "; SameSite=Lax; HttpOnly; Secure" "; SameSite=Lax; HttpOnly")
::
::  +deep-link: open an app's install dialog in the visitor's Landscape
::
::    Landscape's own "show install" route. The visitor's ship fetches
::    the treaty from the publisher directly, so no alliance is needed,
::    but it must be the real publisher, written with its ~.
::
++  deep-link
  |=  [base=@t pub=ship =desk]
  ^-  tape
  "{(trip base)}/apps/landscape/search/direct/apps/{(scow %p pub)}/{(trip desk)}"
::
::  +install-label: the Install button's text for a visitor's saved ship
::
++  install-label
  |=  url=@t
  ^-  tape
  =/  who=(unit ship)  (ship-label url)
  ?~  who  "Install on your ship"
  "Install on {(scow %p u.who)}"
::
::  +ship-name: a saved ship URL as shown to its owner
::
::    The @p when the URL names one, else the host without its scheme.
::
++  ship-name
  |=  url=@t
  ^-  tape
  =/  who=(unit ship)  (ship-label url)
  ?^  who  (scow %p u.who)
  =/  t=tape  (trip url)
  ?:  =("https://" (scag 8 t))  (slag 8 t)
  ?:  =("http://" (scag 7 t))   (slag 7 t)
  t
::
++  install-cmd
  |=  [=ship =desk]
  ^-  tape
  "|install {(scow %p ship)} %{(trip desk)}"
::
++  parse-p    |=(t=@t `(unit ship)`(slaw %p t))
++  parse-tas  |=(t=@t `(unit desk)`(slaw %tas t))
::
::  +normalize-url: validate a visitor's ship URL, keeping scheme and host
::
::    Lowercases, drops whitespace and any path, query or fragment, and
::    defaults to https:// (http:// for a +loopback host, as local
::    development ships are). The host must be dot-separated labels of
::    [a-z0-9-], optionally followed by a port from 1 to 65535.
::
++  normalize-url
  |=  raw=@t
  ^-  (unit @t)
  =/  t=tape
    %+  skip  (cass (trip raw))
    |=(c=@tD |(=(' ' c) =('\09' c) =('\0a' c) =('\0d' c)))
  =/  [scheme=(unit tape) rest=tape]
    ?:  =("https://" (scag 8 t))  [`"https://" (slag 8 t)]
    ?:  =("http://" (scag 7 t))   [`"http://" (slag 7 t)]
    [~ t]
  =/  auth=tape
    |-  ^-  tape
    ?~  rest  ~
    ?:  |(=('/' i.rest) =('?' i.rest) =('#' i.rest))  ~
    [i.rest $(rest t.rest)]
  =/  colon=(unit @ud)  (find ":" auth)
  =/  host=tape  ?~(colon auth (scag u.colon auth))
  =/  port=(unit tape)  ?~(colon ~ `(slag +(u.colon) auth))
  ?.  (valid-host host)  ~
  ?:  ?&  ?=(^ port)
          ?|  =(~ u.port)
              (gth (lent u.port) 5)
              !(levy u.port is-digit)
              =(0 (rash (crip u.port) dem))
              (gth (rash (crip u.port) dem) 65.535)
      ==  ==
    ~
  =/  default=tape  ?:((loopback host) "http://" "https://")
  `(crip (weld (fall scheme default) auth))
::
::  +loopback: is a host this machine (localhost, or 127.x.x.x)?
::
++  loopback
  |=  host=tape
  ^-  ?
  ?|  =("localhost" host)
      &(=("127." (scag 4 host)) (levy host |=(c=@tD |((is-digit c) =('.' c)))))
  ==
::
++  valid-host
  |=  host=tape
  ^-  ?
  ?:  |(=(~ host) (gth (lent host) 253))  |
  %+  levy  (split host '.')
  |=  label=tape
  ?&  !=(~ label)
      (lte (lent label) 63)
      (levy label |=(c=@tD |((is-lower c) (is-digit c) =('-' c))))
  ==
::
::  +ship-label: the @p named by a ship URL's first DNS label, if any
::
::    https://sampel-palnet.tlon.network → ~sampel-palnet
::
::    Galaxy and star names are also everyday words (dev., web., net.,
::    master., winter.), so those only count on hosts that name ships.
::
++  ship-label
  |=  url=@t
  ^-  (unit ship)
  =/  auth=tape  (authority url)
  =/  host=tape  (scag (fall (find ":" auth) (lent auth)) auth)
  =/  dot=@ud  (fall (find "." host) (lent host))
  =/  who=(unit ship)  (slaw %p (crip ['~' (scag dot host)]))
  ?~  who  ~
  ?:  (gth u.who 0xffff)  who
  ?:  (~(has in ship-hosts) (slag +(dot) host))  who
  ~
::
::  +ship-hosts: hosting domains whose subdomains are ship names
::
++  ship-hosts
  ^-  (set tape)
  (silt ~["arvo.network" "tlon.network" "startram.io"])
::
::  +web-url: a URL fit for an href or src, else ~
::
::    Dockets also come from other ships, so only http(s) gets through:
::    no javascript:, data: and so on.
::
++  web-url
  |=  url=@t
  ^-  (unit @t)
  =/  t=tape  (cass (trip (end [3 8] url)))
  ?.  |(=("https://" t) =("http://" (scag 7 t)))  ~
  `url
::
::  +image-url: a URL fit for an <img src>: http(s), or an inline image
::
::    A docket may carry its icon as a data:image/ URL, so it shows
::    without a server. An <img> can't run script, whatever it loads.
::
++  image-url
  |=  url=@t
  ^-  (unit @t)
  ?^  (web-url url)  `url
  ?.  =("data:image/" (cass (trip (end [3 11] url))))  ~
  `url
::
::  +header: a request header, matching its name case-insensitively
::
++  header
  |=  [name=@t =header-list:http]
  ^-  (unit @t)
  =/  key=tape  (cass (trip name))
  |-  ^-  (unit @t)
  ?~  header-list  ~
  ?:  =(key (cass (trip key.i.header-list)))  `value.i.header-list
  $(header-list t.header-list)
::
::  +get-cookie: a cookie's value from a request's Cookie headers
::
::    Browsers send one Cookie header, but HTTP/2 may split it into
::    several, and Eyre passes each one through.
::
++  get-cookie
  |=  [name=@t =header-list:http]
  ^-  (unit @t)
  ?~  header-list  ~
  =/  hit=(unit @t)
    ?.  =("cookie" (cass (trip key.i.header-list)))  ~
    (cookie name value.i.header-list)
  ?^  hit  hit
  $(header-list t.header-list)
::
::  +header-all: a request header's values, comma-joined
::
::    For list headers like Accept, where repeated lines mean the same as
::    one comma-separated line.
::
++  header-all
  |=  [name=@t =header-list:http]
  ^-  (unit @t)
  =/  key=tape  (cass (trip name))
  =/  vs=(list tape)
    %+  murn  header-list
    |=([k=@t v=@t] ?.(=(key (cass (trip k))) ~ `(trip v)))
  ?~  vs  ~
  `(crip (zing (join ", " vs)))
::
::  +form-args: an application/x-www-form-urlencoded body, as a map
::
++  form-args
  |=  body=(unit octs)
  ^-  (map @t @t)
  ?~  body  ~
  =/  rl  (rush (cat 3 '/?' q.u.body) ;~(plug apat:de-purl:html yque:de-purl:html))
  ?~  rl  ~
  (malt +.u.rl)
::
::  +cookie: a cookie's value from a Cookie header
::
++  cookie
  |=  [name=@t hed=@t]
  ^-  (unit @t)
  =/  parts=(list tape)  (split (trip hed) ';')
  |-  ^-  (unit @t)
  ?~  parts  ~
  =/  part=tape  (strip i.parts)
  =/  eq=(unit @ud)  (find "=" part)
  ?:  &(?=(^ eq) =((trip name) (scag u.eq part)))
    `(crip (slag +(u.eq) part))
  $(parts t.parts)
::
::  +is-secure: did the visitor connect over HTTPS?
::
::    Eyre's flag only covers its own socket. A TLS-terminating proxy in
::    front of the ship shows up as X-Forwarded-Proto instead.
::
++  is-secure
  |=  [secure=? =header-list:http]
  ^-  ?
  ?:  secure  &
  =/  proto=(unit @t)  (header 'x-forwarded-proto' header-list)
  ?~  proto  |
  =/  first=tape  (snag 0 (split (trip u.proto) ','))
  =("https" (cass (strip first)))
::
::  +same-origin: did this request come from a page on our own origin?
::
::    Uses Sec-Fetch-Site when the browser sends it, else compares the
::    Origin's (or failing that, the Referer's) host with the Host header.
::
++  same-origin
  |=  =header-list:http
  ^-  ?
  =/  site=(unit @t)  (header 'sec-fetch-site' header-list)
  ?^  site  =('same-origin' u.site)
  =/  host=(unit @t)  (header 'host' header-list)
  =/  from=(unit @t)
    =/  origin=(unit @t)  (header 'origin' header-list)
    ?^(origin origin (header 'referer' header-list))
  ?:  |(?=(~ host) ?=(~ from))  |
  =((cass (authority u.from)) (cass (trip u.host)))
::
::  +authority: a URL's host[:port], without scheme or path
::
++  authority
  |=  url=@t
  ^-  tape
  =/  t=tape  (trip url)
  =?  t  =("https://" (scag 8 t))  (slag 8 t)
  =?  t  =("http://" (scag 7 t))   (slag 7 t)
  |-  ^-  tape
  ?~  t  ~
  ?:  |(=('/' i.t) =('?' i.t) =('#' i.t))  ~
  [i.t $(t t.t)]
::
::  +wants-json: does an Accept header prefer JSON to HTML?
::
::    Compares the quality the header gives application/json and
::    text/html, each from its most specific matching range. Equal
::    qualities go to the type named more specifically, so
::    "application/json, */*" gets JSON. Full ties go to HTML, so
::    browsers and a bare */* get the page.
::
++  wants-json
  |=  accept=(unit @t)
  ^-  ?
  ?~  accept  |
  =/  ranges  (parse-accept u.accept)
  =/  jq  (quality ranges "application" "json")
  =/  hq  (quality ranges "text" "html")
  ?|  (gth q.jq q.hq)
      &(=(q.jq q.hq) (gth q.jq 0) (gth spec.jq spec.hq))
  ==
::
::  +parse-accept: an Accept header as [media-range quality] pairs
::
::    Quality is in thousandths (q=0.8 is 800). No q means 1.000.
::
++  parse-accept
  |=  accept=@t
  ^-  (list [range=tape q=@ud])
  %+  turn  (split (cass (trip accept)) ',')
  |=  part=tape
  ^-  [range=tape q=@ud]
  =/  bits=(list tape)  (turn (split part ';') strip)
  ?~  bits  [~ 0]
  :-  i.bits
  =/  qs=(list @ud)
    %+  murn  t.bits
    |=  bit=tape
    ^-  (unit @ud)
    ?.  =("q=" (scag 2 bit))  ~
    `(parse-q (slag 2 bit))
  ?~(qs 1.000 i.qs)
::
::  +parse-q: a quality value in thousandths, 0 if malformed
::
++  parse-q
  |=  t=tape
  ^-  @ud
  =/  res  (rust t ;~(plug dem (punt ;~(pfix dot (star nud)))))
  ?~  res  0
  =/  frac=tape  (scag 3 (fall +.u.res ~))
  =.  frac  (weld frac (reap (sub 3 (lent frac)) `@tD`'0'))
  %+  min  1.000
  %+  add  (mul 1.000 -.u.res)
  (roll frac |=([c=@tD n=@ud] (add (mul 10 n) (sub c '0'))))
::
::  +quality: the quality an Accept header gives a media type
::
::    The most specific matching range wins: type/subtype (spec 3), then
::    type/* (2), then */* (1). No match is quality 0, spec 0.
::
++  quality
  |=  [ranges=(list [range=tape q=@ud]) typ=tape sub-typ=tape]
  ^-  [q=@ud spec=@ud]
  =/  best=[spec=@ud q=@ud]  [0 0]
  |-  ^-  [q=@ud spec=@ud]
  ?~  ranges  [q.best spec.best]
  =*  r  range.i.ranges
  =/  spec=@ud
    ?:  =(r :(weld typ "/" sub-typ))  3
    ?:  =(r (weld typ "/*"))  2
    ?:  =(r "*/*")  1
    0
  =?  best  &((gth spec 0) (gth spec spec.best))  [spec q.i.ranges]
  =?  best  &((gth spec 0) =(spec spec.best))  [spec (max q.best q.i.ranges)]
  $(ranges t.ranges)
::
::  +hex-color: a docket color as #rrggbb
::
++  hex-color
  |=  c=@ux
  ^-  tape
  ['#' ((x-co:co 6) (end [3 3] c))]
::
::  +tile-ink: text color on a tile, by perceived brightness
::
::    Dark ink when 0.299R + 0.587G + 0.114B > 150 (of 255).
::
++  tile-ink
  |=  c=@ux
  ^-  tape
  =/  r=@  (cut 3 [2 1] c)
  =/  g=@  (cut 3 [1 1] c)
  =/  b=@  (cut 3 [0 1] c)
  ?:  (gth :(add (mul r 299) (mul g 587) (mul b 114)) 150.000)
    "#151514"
  "#ffffff"
::
++  version-tape
  |=  [major=@ud minor=@ud patch=@ud]
  ^-  tape
  "{(a-co:co major)}.{(a-co:co minor)}.{(a-co:co patch)}"
::
::  +anchor: a row's fragment id, {desk}-{publisher without ~}
::
++  anchor
  |=  [=ship =desk]
  ^-  tape
  "{(trip desk)}-{(slag 1 (scow %p ship))}"
::
::  +initial: the first character of a title, for a tile with no image
::
::    Decodes just that character. Titles can come from other ships, so a
::    control character or bad UTF-8 gives "" rather than a crash.
::
++  initial
  |=  title=@t
  ^-  tape
  =/  t=tape  (trip title)
  ?~  t  ~
  =/  n=@ud
    ?:  (lth i.t 0x80)  1
    ?:  (lth i.t 0xe0)  2
    ?:  (lth i.t 0xf0)  3
    4
  =/  bytes=tape  (scag n `tape`t)
  (fall (mole |.((tufa (tuba bytes)))) ~)
::
::  +split: split a tape on a separator character
::
++  split
  |=  [t=tape sep=@tD]
  ^-  (list tape)
  =|  cur=tape
  =|  out=(list tape)
  |-  ^-  (list tape)
  ?~  t  (flop [(flop cur) out])
  ?:  =(sep i.t)  $(t t.t, cur ~, out [(flop cur) out])
  $(t t.t, cur [i.t cur])
::
::  +strip: drop leading and trailing spaces and tabs
::
++  strip
  |=  t=tape
  ^-  tape
  |^  (flop (lead (flop (lead t))))
  ++  lead
    |=  t=tape
    ^-  tape
    ?~  t  ~
    ?.  |(=(' ' i.t) =('\09' i.t))  t
    $(t t.t)
  --
::
++  is-digit  |=(c=@tD &((gte c '0') (lte c '9')))
++  is-lower  |=(c=@tD &((gte c 'a') (lte c 'z')))
::
::  +give-chunked: give-simple-payload:app:server with the body split
::
::    The body goes out in 16 KiB %http-response-data facts: one big
::    fact costs time quadratic in its size (64 KB ~0.15 s, 512 KB ~10 s).
::
++  give-chunked
  |=  [eyre-id=@ta =simple-payload:http]
  ^-  (list card:agent:gall)
  =/  pax=(list path)  ~[/http-response/[eyre-id]]
  =/  dat=(unit octs)  data.simple-payload
  =/  bod=(list card:agent:gall)
    ?~  dat  ~
    =|  out=(list card:agent:gall)
    =/  off=@ud  0
    |-  ^-  (list card:agent:gall)
    ?:  (gte off p.u.dat)  (flop out)
    =/  len=@ud  (min 16.384 (sub p.u.dat off))
    =/  chunk=octs  [len (cut 3 [off len] q.u.dat)]
    %=  $
      off  (add off len)
      out  [[%give %fact pax %http-response-data !>(`(unit octs)``chunk)] out]
    ==
  =/  hed=card:agent:gall
    [%give %fact pax %http-response-header !>(response-header.simple-payload)]
  [hed (snoc bod `card:agent:gall`[%give %kick pax ~])]
::
::  +ui: the HTML page
::
++  ui
  |_  $:  our=ship
          rows=(list treaty:treaty)  ::  sorted
          open=(unit [ship desk])    ::  the row with its install panel open
          err=?                      ::  the URL entered in that panel was bad
          mine=(unit @t)             ::  the visitor's saved ship URL
      ==
  ::
  ::  +document: the whole page, with the owner's raw HTML spliced in
  ::
  ++  document
    |=  [css=@t js=@t head=@t body=@t]
    ^-  tape
    =/  me=tape  (scow %p our)
    =/  head-els=(list manx)
      :~  ;meta(charset "utf-8");
          ;meta(name "viewport", content "width=device-width, initial-scale=1");
          ;meta(name "color-scheme", content "light dark");
        ::  query-relative, so it resolves on the proxy's / and the
        ::  ship's /shelf alike; an explicit icon also stops browsers
        ::  asking the proxy for /favicon.ico, a second page render
        ::
        ;link(rel "icon", type "image/svg+xml", href "?asset=favicon.svg");
          ;title: {me} · Apps
          ;style: {(trip css)}
      ==
    =/  script=manx  ;script: {(trip js)}
    %-  zing
    ^-  (list tape)
    :~  "<!doctype html><html lang=\"en\"><head>"
        (zing (turn head-els en-xml:html))
        (trip head)
        "</head><body>"
        (en-xml:html (main me))
        (en-xml:html script)
        (trip body)
        "</body></html>"
    ==
  ::
  ++  main
    |=  me=tape
    ^-  manx
    ;main(class ?~(mine "page" "page saved"))
      ;header.masthead
        ;div.sigil(aria-hidden "true")
          ;*  (drop (sigil-svg our))
        ==
        ;div
          ;h1: {me}
          ;+  explainer
        ==
      ==
      ;section.apps(aria-label "Published apps")
        ;*  ?~  rows
              :~  ;p.empty: No apps published yet.
              ==
            [(head-row (lent rows)) (turn rows row)]
      ==
    ==
  ::
  ::  +explainer: the masthead's line; returning visitors can change ship
  ::
  ++  explainer
    ^-  manx
    ?~  mine
      ;p
        ; Apps this ship publishes for anyone on Urbit to install. New to Urbit?
        ;a(href "https://urbit.org", target "_blank", rel "noopener"): Start at urbit.org
      ==
    ;p
      ; Apps this ship publishes for anyone on Urbit to install. Installs open on {(ship-name u.mine)}.
      ;a.change(href "/?forget"): Change ship
    ==
  ::
  ++  head-row
    |=  n=@ud
    ^-  manx
    ;div.apps-head
      ;span;
      ;span: App
      ;span: Description
      ;span: Version
      ;span;
      ;span.count: {(a-co:co n)} {?:(=(1 n) "app" "apps")}
    ==
  ::
  ++  row
    |=  t=treaty:treaty
    ^-  manx
    =*  d  docket.t
    =/  pub=tape  (scow %p ship.t)
    =/  cmd=tape  (install-cmd ship.t desk.t)
    =/  is-open=?  =(open `[ship.t desk.t])
    =/  img=(unit @t)  (biff image.d image-url)
    =/  site=(unit @t)  ?:(=('' website.d) ~ (web-url website.d))
    ;article.app(id (anchor ship.t desk.t))
      ;div.app-row
        ;div.tile(style "--tile:{(hex-color color.d)};--tile-ink:{(tile-ink color.d)}")
          ;+  ?~  img
                ;span.initial: {(initial title.d)}
              ;img(src (trip u.img), alt "", loading "lazy");
        ==
        ;div.app-name
          ;strong: {(trip title.d)}
          ;*  ?:  =(ship.t our)  ~
              :~  ;span.app-by: from {pub}
              ==
        ==
        ;div.app-desc
          ;span.app-info: {(trip info.d)}
          ;span.cmd
            ;code: {cmd}
            ;button.copy(type "button", data-copy cmd, hidden ""): Copy
          ==
        ==
        ;span.version: {(version-tape version.d)}
        ;+  ?~  site
              ;span;
            ;a.site(href (trip u.site), target "_blank", rel "noopener"): Website ↗
        ;div.install-cell
          ;+  (install-button t is-open)
        ==
      ==
      ;*  ?.  is-open  ~
          :~  (panel t cmd)
          ==
    ==
  ::
  ++  install-button
    |=  [t=treaty:treaty is-open=?]
    ^-  manx
    =/  anc=tape  (anchor ship.t desk.t)
    ?:  is-open
      ;a.btn.btn-outline(href "/#{anc}"): Close
    ?~  mine
      ;a.btn(href "/?install={(trip desk.t)}&host={(scow %p ship.t)}#{anc}"): Install
    ;a.btn(href (deep-link u.mine ship.t desk.t)): {(install-label u.mine)}
  ::
  ++  panel
    |=  [t=treaty:treaty cmd=tape]
    ^-  manx
    ;div.panel-wrap
      ;span.tile-ext(style "--tile:{(hex-color color.docket.t)}");
      ;form.panel(method "post", action "/")
        ;input(type "hidden", name "install", value (trip desk.t));
        ;input(type "hidden", name "host", value (scow %p ship.t));
        ;div.panel-col
          ;label(for "ship-url"): Install {(trip title.docket.t)} on your ship
          ;div.field-row
            ;input#ship-url(type "text", name "url", inputmode "url", autocomplete "url", required "", placeholder "sampel-palnet.tlon.network", value (trip (fall mine '')));
            ;button.btn.btn-lg(type "submit"): Open on my ship →
          ==
          ;+  ?:  err
                ;span.error: That doesn't look like a ship URL. Try sampel-palnet.tlon.network.
              ;span.hint: Enter your ship's URL once. It's remembered on this device.
        ==
        ;div.panel-col.dojo-col
          ;span.label: Or run in Dojo
          ;div.dojo
            ;code: {cmd}
            ;button.copy(type "button", data-copy cmd, hidden ""): Copy
          ==
        ==
      ==
    ==
  --
::
::  +clean-utf8: well-formed UTF-8 kept, any other byte as U+FFFD
::
::    Dockets can come from other ships, and nothing checks that their
::    text is UTF-8, but JSON must be.
::
++  clean-utf8
  |=  t=@t
  ^-  @t
  =/  len=@ud  (met 3 t)
  =|  [i=@ud out=(list [@ud @])]
  |-  ^-  @t
  ?:  (gte i len)  (can 3 (flop out))
  =/  c=@  (cut 3 [i 1] t)
  ?:  (lth c 0x80)  $(i +(i), out [[1 c] out])
  ::  the sequence's length, and the range of its second byte
  ::
  =/  [n=@ud lo=@ hi=@]
    ?:  &((gte c 0xc2) (lte c 0xdf))  [2 0x80 0xbf]
    ?:  =(0xe0 c)  [3 0xa0 0xbf]
    ?:  =(0xed c)  [3 0x80 0x9f]
    ?:  &((gte c 0xe1) (lte c 0xef))  [3 0x80 0xbf]
    ?:  =(0xf0 c)  [4 0x90 0xbf]
    ?:  =(0xf4 c)  [4 0x80 0x8f]
    ?:  &((gte c 0xf1) (lte c 0xf3))  [4 0x80 0xbf]
    [0 0 0]
  =/  at  |=(k=@ud `@`(cut 3 [(add i k) 1] t))
  =/  cont  |=(k=@ud |((gte k n) &((gte (at k) 0x80) (lte (at k) 0xbf))))
  ?.  ?&  !=(0 n)
          (lte (add i n) len)
          (gte (at 1) lo)
          (lte (at 1) hi)
          (cont 2)
          (cont 3)
      ==
    $(i +(i), out [[3 0xbd.bfef] out])
  $(i (add i n), out [[n (cut 3 [i n] t)] out])
::
::  +treaty-json: one app for the JSON listing, docket plus hash
::
++  treaty-json
  |=  t=treaty:treaty
  ^-  json
  =*  d  docket.t
  %-  pairs:enjs:format
  :~  ship+s+(scot %p ship.t)
      desk+s+desk.t
      title+s+(clean-utf8 title.d)
      info+s+(clean-utf8 info.d)
      color+s+(crip (hex-color color.d))
      image+?~(image.d ~ s+(clean-utf8 u.image.d))
      version+s+(crip (version-tape version.d))
      website+s+(clean-utf8 website.d)
      license+s+(clean-utf8 license.d)
      hash+s+(scot %uv hash.t)
      install+s+(crip (install-cmd ship.t desk.t))
  ==
--
