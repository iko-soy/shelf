::  shelf: a public listing of the apps this ship publishes
::
::    Serves one page at /shelf listing the %treaty alliance: this
::    ship's own published desks plus any it republishes. The same URL
::    returns JSON when the Accept header asks for it.
::
::    Meant to sit behind a reverse proxy that maps a dedicated domain's
::    / onto /shelf, so the page's links all point at /.
::
::    It also serves its two icons from the desk, at ?asset=favicon.svg
::    and ?asset=shelf-icon.svg.
::
::    The owner can append raw HTML to <head> and <body>, for analytics:
::      :shelf|head '<script defer src="…"></script>'
::      :shelf|body '…'
::
/-  docket, shelf, treaty
/+  default-agent, dbug, server, *shelf
/*  shelf-css  %css  /web/shelf/css
/*  copy-js    %js   /web/copy/js
/*  favicon     %svg  /web/favicon/svg
/*  shelf-icon  %svg  /web/shelf-icon/svg
|%
+$  card  card:agent:gall
+$  state-0
  $:  %0
      head-html=@t  ::  appended to <head>
      body-html=@t  ::  appended to <body>
  ==
--
::
%-  agent:dbug
=|  state-0
=*  state  -
=<
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  [%pass /eyre/connect %arvo %e %connect [~ /shelf] dap.bowl]~
::
++  on-save  !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  ::  re-bind on every load, from on-init's wire (so Eyre just replaces
  ::  it): a binding dropped by hand comes back with the next update
  ::
  :_  this(state !<(state-0 old))
  [%pass /eyre/connect %arvo %e %connect [~ /shelf] dap.bowl]~
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
  ::  the page is public: src is the visitor, often an Eyre guest identity
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    :_  this
    (give-chunked eyre-id (handle:hc req))
  ::
      %shelf-action
    ?>  =(our src):bowl
    =+  !<(act=action:shelf vase)
    ?-  -.act
      %head  `this(head-html html.act)
      %body  `this(body-html html.act)
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?:  ?=([%http-response @ ~] path)  `this
  (on-watch:def path)
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %head ~]  ``noun+!>(head-html)
    [%x %body ~]  ``noun+!>(body-html)
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?.  ?=([%eyre %connect ~] wire)  (on-arvo:def wire sign-arvo)
  ?>  ?=([%eyre %bound *] sign-arvo)
  ~?  !accepted.sign-arvo  [dap.bowl %bind-rejected binding.sign-arvo]
  `this
::
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::  +handle: route a request. Eyre only sends us /shelf and below.
::
++  handle
  |=  req=inbound-request:eyre
  ^-  simple-payload:http
  =/  rl  (parse-request-line:server url.request.req)
  ?.  &(?=(~ ext.rl) ?=(?([%shelf ~] [%shelf %$ ~]) site.rl))
    (plain 404 'Not found')
  =/  hs=header-list:http  header-list.request.req
  =/  secure=?  (is-secure secure.req hs)
  ?:  ?=(%'POST' method.request.req)
    (save (form-args body.request.req) hs secure)
  ?.  ?=(?(%'GET' %'HEAD') method.request.req)
    [[405 ~[['allow' 'GET, HEAD, POST']]] ~]
  =/  q=(map @t @t)  (malt args.rl)
  ?^  name=(~(get by q) 'asset')  (asset u.name)
  ?:  (~(has by q) 'forget')  (forget hs secure)
  ?:  (wants-json (header-all 'accept' hs))  listing-json
  (page q hs)
::
++  plain
  |=  [code=@ud msg=@t]
  ^-  simple-payload:http
  :_  `(as-octs:mimes:html msg)
  [code ~[['content-type' 'text/plain; charset=utf-8']]]
::
++  redirect
  |=  [code=@ud loc=@t]
  ^-  simple-payload:http
  [[code ~[['location' loc] ['cache-control' 'no-store']]] ~]
::
::  +asset: one of the icons in the desk's /web
::
::    private, like the JSON: Eyre adds its session cookie to every
::    response, and for a logged-in owner that is their login token.
::
++  asset
  |=  name=@t
  ^-  simple-payload:http
  =/  file=(unit @)
    ?+  name  ~
      %'favicon.svg'     `favicon
      %'shelf-icon.svg'  `shelf-icon
    ==
  ?~  file  (plain 404 'Not found')
  :_  `(as-octs:mimes:html u.file)
  :-  200
  :~  ['content-type' 'image/svg+xml']
      ['cache-control' 'private, max-age=86400']
      ['x-content-type-options' 'nosniff']
  ==
::
::  +forget: clear the visitor's saved ship
::
::    Only when the browser is navigating here, not when a docket's image
::    URL points here.
::
++  forget
  |=  [hs=header-list:http secure=?]
  ^-  simple-payload:http
  =/  dest=(unit @t)  (header 'sec-fetch-dest' hs)
  ?:  &(?=(^ dest) !=('document' u.dest))  (redirect 303 '/')
  :_  ~
  :-  303
  :~  ['location' '/']
      ['set-cookie' (forget-cookie secure)]
      ['cache-control' 'no-store']
  ==
::
::  +save: the install form, POSTed. Remember the visitor's ship, then
::  open the app there.
::
::    Only for apps on the shelf, and only for a POST from this page:
::    links and images can't POST, and a docket's image or website URL
::    could otherwise point here. So nothing else can plant a ship URL
::    in a visitor's cookie or bounce them elsewhere through this domain.
::
++  save
  |=  [q=(map @t @t) hs=header-list:http secure=?]
  ^-  simple-payload:http
  =/  pub=(unit ship)  (biff (~(get by q) 'host') parse-p)
  =/  dek=(unit desk)  (biff (~(get by q) 'install') parse-tas)
  ?:  |(?=(~ pub) ?=(~ dek))  (redirect 303 '/')
  ?.  (~(has in listed) [u.pub u.dek])  (redirect 303 '/')
  =/  back=tape  "/?install={(trip u.dek)}&host={(scow %p u.pub)}"
  =/  anc=tape  (anchor u.pub u.dek)
  ?.  (same-origin hs)  (redirect 303 (crip "{back}#{anc}"))
  =/  url=(unit @t)  (biff (~(get by q) 'url') normalize-url)
  ?~  url  (redirect 303 (crip "{back}&error=1#{anc}"))
  :_  ~
  :-  303
  :~  ['location' (crip (deep-link u.url u.pub u.dek))]
      ['set-cookie' (ship-cookie u.url secure)]
      ['cache-control' 'no-store']
  ==
::
++  scry
  |=  [=dude:gall =path]
  ^-  ^path
  (weld /(scot %p our.bowl)/[dude]/(scot %da now.bowl) path)
::
::  The scries below are all ones that can't fail. A failed scry would
::  fail the whole request, and +mule can't catch that inside an agent.
::
::  +treaty-running: is %treaty (from %landscape) running?
::
++  treaty-running
  ^-  ?
  .^(? %gu (scry %treaty /$))
::
::  +listed: the alliance, the [ship desk]s this ship advertises
::
++  listed
  ^-  (set [=ship =desk])
  ?.  treaty-running  ~
  =/  =update:alliance:treaty
    .^(update:alliance:treaty %gx (scry %treaty /alliance/noun))
  ?.  ?=(%ini -.update)  ~
  init.update
::
::  +treaties: the alliance's treaties, sorted by title
::
::    Our own desks' treaties are made the way %treaty makes them, from
::    the desk's docket file, since %treaty only exposes foreign ones.
::    An entry whose treaty isn't there (yet) is skipped. Without full,
::    our own desks' case and hash, which only the JSON shows, are left
::    out to save two scries per desk.
::
++  treaties
  |=  full=?
  ^-  (list treaty:treaty)
  =/  entries=(set [=ship =desk])  listed
  =/  foreign=(map [ship desk] treaty:treaty)
    ?:  =(~ entries)  ~
    =/  =update:treaty:treaty
      .^(update:treaty:treaty %gx (scry %treaty /treaties/noun))
    ?.  ?=(%ini -.update)  ~
    init.update
  %+  sort
    %+  murn  ~(tap in entries)
    |=  [=ship =desk]
    ^-  (unit treaty:treaty)
    ?.  =(our.bowl ship)  (~(get by foreign) [ship desk])
    (own-treaty desk full)
  |=  [a=treaty:treaty b=treaty:treaty]
  =/  ta=@t  (crip (cass (trip title.docket.a)))
  =/  tb=@t  (crip (cass (trip title.docket.b)))
  ?.  =(ta tb)  (aor ta tb)
  ?.  =(ship.a ship.b)  (aor ship.a ship.b)
  (aor desk.a desk.b)
::
::  +own-treaty: the treaty %treaty advertises for one of our desks
::
++  own-treaty
  |=  [=desk full=?]
  ^-  (unit treaty:treaty)
  =/  bek=path  /(scot %p our.bowl)/[desk]/(scot %da now.bowl)
  ?.  .^(? %cu (weld bek /desk/docket-0))  ~
  ::  the stored page (%cq), not %cx: %cx builds the desk's own docket
  ::  mark, and if that ever fails to build, the scry fails the request
  ::
  =/  raw  .^(* %cq (weld bek /desk/docket-0))
  =/  dok=(unit docket:docket)  (mole |.(;;(docket:docket raw)))
  ?~  dok  ~
  ?.  full  `[our.bowl desk da+now.bowl *@uv u.dok]
  =/  =cass:clay  .^(cass:clay %cw bek)
  `[our.bowl desk da+da.cass .^(@uv %cz bek) u.dok]
::
::  +listing-json: the shelf as JSON, for Accept: application/json
::
++  listing-json
  ^-  simple-payload:http
  :_  `(as-octs:mimes:html (en:json:html a+(turn (treaties &) treaty-json)))
  :-  200
  ::  private: Eyre adds its session cookie to every response, and for
  ::  a logged-in owner that is their login token
  ::
  :~  ['content-type' 'application/json']
      ['cache-control' 'private, max-age=60']
      ::  Eyre's casing, so Eyre replaces it for origins the owner has
      ::  approved instead of adding a second one
      ::
      ['Access-Control-Allow-Origin' '*']
      ['vary' 'Accept, Origin']
      ['x-content-type-options' 'nosniff']
  ==
::
::  +page: the HTML listing
::
::    ?install=desk&host=~ship opens that app's install panel, and
::    &error=1 says the URL entered there was bad.
::
++  page
  |=  [q=(map @t @t) hs=header-list:http]
  ^-  simple-payload:http
  =/  open=(unit [ship desk])
    %+  both  (biff (~(get by q) 'host') parse-p)
    (biff (~(get by q) 'install') parse-tas)
  =/  mine=(unit @t)  (biff (get-cookie cookie-name hs) normalize-url)
  =/  doc=tape
    %.  [shelf-css copy-js head-html body-html]
    ~(document ui our.bowl (treaties |) open (~(has by q) 'error') mine)
  :_  `(as-octt:mimes:html doc)
  :-  200
  ::  Cookie too, or a browser shows its cached copy after the saved
  ::  ship changes
  ::
  :~  ['content-type' 'text/html; charset=utf-8']
      ['cache-control' 'private, max-age=60']
      ['vary' 'Accept, Cookie']
  ==
--
