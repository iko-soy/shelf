/-  docket, treaty
/+  *test, *shelf
|%
::  fixtures for the page tests
::
++  harbor
  ^-  treaty:treaty
  :*  ~zod  %harbor  da+~2026.1.1  0v1
      %1  'Harbor'  'Every desk on your ship.'  0x24.466f  [%site /apps/harbor]
      `'https://x.y/harbor.svg'  [2 0 1]  'https://github.com/zod/harbor'  'MIT'
  ==
::
++  marginalia
  ^-  treaty:treaty
  :*  ~bus  %marginalia  da+~2026.1.1  0v2
      %1  'Marginalia'  'Annotate any page.'  0x3d.3934  [%site /apps/marginalia]
      ~  [0 4 2]  'https://github.com/bus/marginalia'  'MIT'
  ==
::
++  oddity
  ^-  treaty:treaty
  :*  ~zod  %oddity  da+~2026.1.1  0v3
      %1  '<Odd & "Quoted"> App'  'a < b & c > \'d\''  0xff.ffff  [%site /apps/oddity]
      `'javascript:alert(1)'  [10 20 300]  'javascript:alert(2)'  ''
  ==
::
++  has
  |=  [hay=tape needle=tape]
  ^-  ?
  ?=(^ (find needle hay))
::
++  count
  |=  [hay=tape needle=tape]
  ^-  @ud
  (lent (fand needle hay))
::
++  render
  |=  $:  our=ship
          rows=(list treaty:treaty)
          open=(unit [ship desk])
          err=?
          mine=(unit @t)
      ==
  ^-  tape
  (~(document ui our rows open err mine) 'CSS' 'JS' '' '')
::
++  test-ui-empty
  =/  doc  (render ~zod ~ ~ | ~)
  ;:  weld
    (expect !>((has doc "<p class=\"empty\">No apps published yet.</p>")))
    (expect !>(!(has doc "apps-head")))
    (expect !>((has doc "<title>~zod · Apps</title>")))
    (expect !>((has doc "<style>CSS</style>")))
    (expect !>((has doc "<main class=\"page\">")))
    (expect !>((has doc "<link rel=\"icon\" href=\"data:,\" />")))
    (expect !>((has doc "<script>JS</script>")))
  ==
::
++  test-ui-rows
  =/  doc  (render ~zod ~[harbor marginalia oddity] ~ | ~)
  ;:  weld
    (expect !>((has doc "<span class=\"count\">3 apps</span>")))
    (expect !>(=(1 (count doc "by ~bus"))))
    (expect !>((has doc "<section class=\"apps\" aria-label=\"Published apps\">")))
    (expect !>((has doc "&lt;Odd &amp; &quot;Quoted&quot;&gt; App")))
    (expect !>((has doc "a &lt; b &amp; c &gt; &#39;d&#39;")))
    (expect !>(!(has doc "<Odd")))
    (expect !>(!(has doc "javascript:")))
    (expect !>(=(2 (count doc "class=\"site\""))))
    (expect !>((has doc "<span class=\"initial\">&lt;</span>")))
    (expect !>((has doc "<span class=\"initial\">M</span>")))
    (expect !>((has doc "<img src=\"https://x.y/harbor.svg\"")))
    (expect !>((has doc "--tile:#24466f;--tile-ink:#ffffff")))
    (expect !>((has doc "<span class=\"version\">10.20.300</span>")))
    (expect !>((has doc "href=\"/?install=harbor&amp;host=~zod#harbor-zod\"")))
    (expect !>((has doc "href=\"/?install=marginalia&amp;host=~bus#marginalia-bus\"")))
    (expect !>((has doc "data-copy=\"|install ~bus %marginalia\"")))
    (expect !>((has doc "<article class=\"app\" id=\"oddity-zod\">")))
    (expect !>(!(has doc "panel-wrap")))
    (expect !>((has doc "New to Urbit?\0a<a href=\"https://urbit.org\"")))
  ==
::
++  test-ui-one-app
  =/  doc  (render ~zod ~[harbor] ~ | ~)
  (expect !>((has doc "<span class=\"count\">1 app</span>")))
::
++  test-ui-open-panel
  =/  doc  (render ~zod ~[harbor marginalia] `[~zod %harbor] | ~)
  ;:  weld
    (expect !>(=(1 (count doc "panel-wrap"))))
    (expect !>((has doc "href=\"/#harbor-zod\">Close</a>")))
    (expect !>((has doc "<form class=\"panel\" method=\"post\" action=\"/\">")))
    (expect !>((has doc "name=\"install\" value=\"harbor\"")))
    (expect !>((has doc "name=\"host\" value=\"~zod\"")))
    (expect !>((has doc "Install Harbor on your ship")))
    (expect !>((has doc "<span class=\"hint\">")))
    (expect !>(!(has doc "<span class=\"error\">")))
    (expect !>((has doc "href=\"/?install=marginalia&amp;host=~bus#marginalia-bus\">Install</a>")))
  ==
::
++  test-ui-open-error
  =/  doc  (render ~zod ~[harbor] `[~zod %harbor] & ~)
  ;:  weld
    (expect !>((has doc "<span class=\"error\">That doesn&#39;t look like a ship URL.")))
    (expect !>(!(has doc "<span class=\"hint\">")))
  ==
::
++  test-ui-open-unknown
  ::  ?install= naming an app that isn't on the shelf opens nothing
  =/  doc  (render ~zod ~[harbor] `[~zod %nope] | ~)
  (expect !>(!(has doc "panel-wrap")))
::
++  test-ui-saved-ship
  =/  mine  `'https://sampel-palnet.tlon.network'
  =/  doc  (render ~zod ~[harbor marginalia] ~ | mine)
  ;:  weld
    %-  expect  !>
    %+  has  doc
    "href=\"https://sampel-palnet.tlon.network/apps/landscape/search/direct/apps/~zod/harbor\">Install on ~sampel-palnet</a>"
  ::
    %-  expect  !>
    %+  has  doc
    "/apps/landscape/search/direct/apps/~bus/marginalia\">Install on ~sampel-palnet</a>"
  ::
    %-  expect  !>
    (has doc "Installs open on ~sampel-palnet.\0a<a class=\"change\" href=\"/?forget\">Change ship</a>")
  ::
    (expect !>((has doc "<main class=\"page saved\">")))
    (expect !>(!(has doc "New to Urbit?")))
  ==
::
++  test-ui-saved-ship-panel
  ::  a saved ship prefills the panel's input
  =/  doc  (render ~zod ~[harbor] `[~zod %harbor] | `'http://localhost:8080')
  ;:  weld
    (expect !>((has doc "value=\"http://localhost:8080\"")))
    (expect !>((has doc "Installs open on localhost:8080.")))
  ==
::
++  test-ui-raw-html
  =/  doc
    %.  ['' '' '<script id="h"></script>' '<script id="b"></script>']
    ~(document ui ~zod ~ ~ | ~)
  ;:  weld
    (expect !>((has doc "<script id=\"h\"></script></head><body>")))
    (expect !>((has doc "<script id=\"b\"></script></body></html>")))
    (expect !>(=("<!doctype html>" (scag 15 doc))))
  ==
::
++  test-ui-sigil
  ;:  weld
    (expect !>((has (render ~zod ~ ~ | ~) "<div class=\"sigil\" aria-hidden=\"true\"><svg")))
    (expect !>((has (render ~sampel-palnet ~ ~ | ~) "<div class=\"sigil\" aria-hidden=\"true\"><svg")))
    %-  expect  !>
    %+  has  (render ~doprut-posfel-sampel-palnet ~ ~ | ~)
    "<div class=\"sigil\" aria-hidden=\"true\"></div>"
  ==
::
++  test-sigil-colors
  =/  svg  (en-xml:html (need (sigil-svg ~sampel-palnet)))
  ;:  weld
    (expect !>((has svg "fill=\"currentColor\"")))
    (expect !>((has svg "style=\"fill:var(--ink)\"")))
    (expect !>(!(has svg "=\"var(--ink)\"")))
    (expect !>(!(has svg "width: ")))
    (expect !>((has svg "transform=\"translate(16 16) scale(0.375)\"")))
  ==
::
++  test-give-chunked
  =/  big=@  (fil 3 40.000 'x')
  =/  cards=(list card:agent:gall)  (give-chunked 'id' [[200 ~] `[40.000 big]])
  =/  chunks=(list octs)
    %+  murn  cards
    |=  c=card:agent:gall
    ^-  (unit octs)
    ?.  ?=(%give -.c)  ~
    ?.  ?=(%fact -.p.c)  ~
    ?.  =(%http-response-data p.cage.p.c)  ~
    !<((unit octs) q.cage.p.c)
  ;:  weld
    (expect-eq !>(~[16.384 16.384 7.232]) !>((turn chunks head)))
    (expect-eq !>(big) !>((can 3 chunks)))
    (expect-eq !>(5) !>((lent cards)))
    (expect-eq !>(2) !>((lent (give-chunked 'id' [[303 ~] ~]))))
  ==
::
++  test-clean-utf8
  ;:  weld
    (expect-eq !>('Café ✓ 🎉') !>((clean-utf8 'Café ✓ 🎉')))
    (expect-eq !>('Caf\ef\bf\bd') !>((clean-utf8 'Caf\e9')))
    (expect-eq !>('\ef\bf\bd\ef\bf\bdx') !>((clean-utf8 '\c0\afx')))
    (expect-eq !>('a\ef\bf\bd\ef\bf\bd') !>((clean-utf8 'a\e2\82')))
    (expect-eq !>('') !>((clean-utf8 '')))
  ==
::
++  test-treaty-json
  =/  one  (en:json:html (treaty-json harbor))
  =/  two  (en:json:html (treaty-json marginalia))
  ;:  weld
    (expect !>((has (trip one) "\"install\":\"|install ~zod %harbor\"")))
    (expect !>((has (trip one) "\"color\":\"#24466f\"")))
    (expect !>((has (trip one) "\"image\":\"https://x.y/harbor.svg\"")))
    (expect !>((has (trip one) "\"version\":\"2.0.1\"")))
    (expect !>((has (trip one) "\"hash\":\"0v1\"")))
    (expect !>((has (trip two) "\"image\":null")))
    (expect !>((has (trip two) "\"ship\":\"~bus\"")))
  ==
::
++  test-normalize-url
  =/  ok
    |=  [in=@t out=@t]
    (expect-eq !>(`(unit @t)``out) !>((normalize-url in)))
  =/  bad
    |=  in=@t
    (expect-eq !>(`(unit @t)`~) !>((normalize-url in)))
  ;:  weld
    (ok 'sampel-palnet.tlon.network' 'https://sampel-palnet.tlon.network')
    (ok ' HTTPS://Sampel-Palnet.Tlon.Network/ ' 'https://sampel-palnet.tlon.network')
    (ok 'https://sampel-palnet.tlon.network/apps/landscape/' 'https://sampel-palnet.tlon.network')
    (ok 'https://zod.example.com?x=1#y' 'https://zod.example.com')
    (ok 'http://localhost:8080' 'http://localhost:8080')
    (ok 'https://localhost:8443' 'https://localhost:8443')
    (ok 'localhost:8080/' 'http://localhost:8080')
    (ok '127.0.0.1:8080' 'http://127.0.0.1:8080')
    (ok 'localhost.example.com' 'https://localhost.example.com')
    (ok '127.example.com' 'https://127.example.com')
    (ok 'example.com:65535' 'https://example.com:65535')
    (ok '192.168.1.5:8080' 'https://192.168.1.5:8080')
    (ok 'sampel - palnet.tlon.network' 'https://sampel-palnet.tlon.network')
    (bad '')
    (bad '   ')
    (bad 'https://')
    (bad 'https:///apps')
    (bad 'ftp://example.com')
    (bad 'javascript:alert(1)')
    (bad 'user@example.com')
    (bad 'example..com')
    (bad 'ex_ample.com')
    (bad '~sampel-palnet')
    (bad 'example.com:')
    (bad 'example.com:123456')
    (bad 'example.com:80a')
    (bad 'example.com:65536')
    (bad 'example.com:0')
  ==
::
++  test-ship-label
  ;:  weld
    %+  expect-eq  !>(`(unit ship)``~sampel-palnet)
    !>((ship-label 'https://sampel-palnet.tlon.network'))
  ::
    %+  expect-eq  !>(`(unit ship)``~zod)
    !>((ship-label 'https://zod.arvo.network'))
  ::
    %+  expect-eq  !>(`(unit ship)``~marzod)
    !>((ship-label 'https://marzod.tlon.network:443'))
  ::
    %+  expect-eq  !>(`(unit ship)`~)
    !>((ship-label 'http://zod:8080'))
  ::
    %+  expect-eq  !>(`(unit ship)`~)
    !>((ship-label 'https://dev.example.com'))
  ::
    %+  expect-eq  !>(`(unit ship)`~)
    !>((ship-label 'https://master.example.com'))
  ::
    %+  expect-eq  !>(`(unit ship)``~sampel-palnet)
    !>((ship-label 'https://sampel-palnet.example.com'))
  ::
    %+  expect-eq  !>(`(unit ship)`~)
    !>((ship-label 'http://localhost:8080'))
  ::
    %+  expect-eq  !>(`(unit ship)`~)
    !>((ship-label 'https://apps.example.com'))
  ==
::
++  test-web-url
  ;:  weld
    (expect-eq !>(`(unit @t)``'https://a.b/i.png') !>((web-url 'https://a.b/i.png')))
    (expect-eq !>(`(unit @t)``'HTTP://a.b') !>((web-url 'HTTP://a.b')))
    (expect-eq !>(`(unit @t)`~) !>((web-url 'javascript:alert(1)')))
    (expect-eq !>(`(unit @t)`~) !>((web-url '//evil.com/x')))
    (expect-eq !>(`(unit @t)`~) !>((web-url 'data:image/png;base64,AAAA')))
    (expect-eq !>(`(unit @t)`~) !>((web-url '')))
  ==
::
++  test-header
  =/  hs=header-list:http
    ~[['Accept' 'text/html'] ['cookie' 'a=1']]
  ;:  weld
    (expect-eq !>(`(unit @t)``'text/html') !>((header 'accept' hs)))
    (expect-eq !>(`(unit @t)``'a=1') !>((header 'Cookie' hs)))
    (expect-eq !>(`(unit @t)`~) !>((header 'host' hs)))
  ==
::
++  test-cookie
  ;:  weld
    %+  expect-eq  !>(`(unit @t)``'https://a.b')
    !>((cookie 'shelf-ship' 'x=1; shelf-ship=https://a.b; y=2'))
  ::
    %+  expect-eq  !>(`(unit @t)``'')
    !>((cookie 'shelf-ship' 'shelf-ship='))
  ::
    %+  expect-eq  !>(`(unit @t)`~)
    !>((cookie 'shelf-ship' 'shelf-shipx=1; xshelf-ship=2'))
  ::
    %+  expect-eq  !>(`(unit @t)`~)
    !>((cookie 'shelf-ship' ''))
  ==
::
++  test-get-cookie
  ;:  weld
    %+  expect-eq  !>(`(unit @t)``'https://a.b')
    !>((get-cookie 'shelf-ship' ~[['cookie' 'x=1'] ['Cookie' 'shelf-ship=https://a.b']]))
  ::
    %+  expect-eq  !>(`(unit @t)`~)
    !>((get-cookie 'shelf-ship' ~[['accept' 'shelf-ship=1'] ['cookie' 'x=1']]))
  ::
    (expect-eq !>(`(unit @t)`~) !>((get-cookie 'shelf-ship' ~)))
  ==
::
++  test-cookies-out
  ;:  weld
    %+  expect-eq
      !>('shelf-ship=https://a.b; Path=/; Max-Age=31536000; SameSite=Lax; HttpOnly; Secure')
    !>((ship-cookie 'https://a.b' &))
  ::
    %+  expect-eq
      !>('shelf-ship=http://a.b:8080; Path=/; Max-Age=31536000; SameSite=Lax; HttpOnly')
    !>((ship-cookie 'http://a.b:8080' |))
  ::
    %+  expect-eq
      !>('shelf-ship=; Path=/; Max-Age=0; SameSite=Lax; HttpOnly')
    !>((forget-cookie |))
  ==
::
++  test-labels
  ;:  weld
    (expect-eq !>("Install on ~sampel-palnet") !>((install-label 'https://sampel-palnet.tlon.network')))
    (expect-eq !>("Install on your ship") !>((install-label 'http://localhost:8080')))
    (expect-eq !>("~sampel-palnet") !>((ship-name 'https://sampel-palnet.tlon.network')))
    (expect-eq !>("localhost:8080") !>((ship-name 'http://localhost:8080')))
    (expect-eq !>("|install ~zod %harbor") !>((install-cmd ~zod %harbor)))
    %+  expect-eq
      !>("https://a.b/apps/landscape/search/direct/apps/~zod/harbor")
    !>((deep-link 'https://a.b' ~zod %harbor))
  ==
::
++  test-header-all
  =/  hs=header-list:http
    ~[['accept' 'text/html;q=0.1'] ['Host' 'a.b'] ['Accept' 'application/json']]
  ;:  weld
    %+  expect-eq  !>(`(unit @t)``'text/html;q=0.1, application/json')
    !>((header-all 'accept' hs))
  ::
    (expect-eq !>(`(unit @t)`~) !>((header-all 'cookie' hs)))
    (expect !>((wants-json (header-all 'accept' hs))))
  ==
::
++  test-form-args
  ;:  weld
    %+  expect-eq
      !>((malt ~[['install' 'harbor'] ['host' '~zod'] ['url' 'a b:8080/']]))
    !>((form-args `(as-octs:mimes:html 'install=harbor&host=%7Ezod&url=a+b%3A8080%2F')))
  ::
    (expect-eq !>(*(map @t @t)) !>((form-args ~)))
    (expect-eq !>(*(map @t @t)) !>((form-args `(as-octs:mimes:html 'x=a@b'))))
  ==
::
++  test-is-secure
  ;:  weld
    (expect-eq !>(&) !>((is-secure & ~)))
    (expect-eq !>(|) !>((is-secure | ~)))
    (expect-eq !>(&) !>((is-secure | ~[['x-forwarded-proto' 'https']])))
    (expect-eq !>(&) !>((is-secure | ~[['X-Forwarded-Proto' ' HTTPS, http']])))
    (expect-eq !>(|) !>((is-secure | ~[['x-forwarded-proto' 'http']])))
  ==
::
++  test-same-origin
  ;:  weld
    (expect-eq !>(&) !>((same-origin ~[['sec-fetch-site' 'same-origin']])))
    %+  expect-eq  !>(|)
    !>((same-origin ~[['sec-fetch-site' 'cross-site'] ['host' 'a.b'] ['referer' 'https://a.b/']]))
  ::
    %+  expect-eq  !>(&)
    !>((same-origin ~[['host' 'Apps.Example.com'] ['referer' 'https://apps.example.com/?install=x']]))
  ::
    %+  expect-eq  !>(|)
    !>((same-origin ~[['host' 'apps.example.com'] ['referer' 'https://evil.com/apps.example.com']]))
  ::
    %+  expect-eq  !>(|)
    !>((same-origin ~[['host' 'apps.example.com:8443'] ['referer' 'https://apps.example.com/']]))
  ::
    (expect-eq !>(|) !>((same-origin ~)))
    %+  expect-eq  !>(&)
    !>((same-origin ~[['host' 'apps.example.com'] ['origin' 'https://apps.example.com']]))
  ::
    %+  expect-eq  !>(|)
    !>((same-origin ~[['host' 'apps.example.com'] ['origin' 'null'] ['referer' 'https://apps.example.com/']]))
  ::
    %+  expect-eq  !>(|)
    !>((same-origin ~[['host' 'apps.example.com'] ['origin' 'https://evil.example']]))
  ==
::
++  test-wants-json
  ;:  weld
    (expect-eq !>(|) !>((wants-json ~)))
    (expect-eq !>(&) !>((wants-json `'application/json')))
    (expect-eq !>(&) !>((wants-json `'Application/JSON; charset=utf-8')))
    (expect-eq !>(&) !>((wants-json `'application/json, text/plain, */*')))
    (expect-eq !>(&) !>((wants-json `'application/*')))
    (expect-eq !>(&) !>((wants-json `'text/html;q=0.5, application/json;q=0.9')))
    %+  expect-eq  !>(|)
    !>((wants-json `'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'))
  ::
    (expect-eq !>(|) !>((wants-json `'*/*')))
    (expect-eq !>(|) !>((wants-json `'')))
    (expect-eq !>(|) !>((wants-json `'text/html, application/json')))
    (expect-eq !>(|) !>((wants-json `'application/json;q=0, */*')))
    (expect-eq !>(|) !>((wants-json `'*/*;q=0.5, application/json;q=0.4')))
    (expect-eq !>(|) !>((wants-json `'text/*')))
  ==
::
++  test-parse-q
  ;:  weld
    (expect-eq !>(1.000) !>((parse-q "1")))
    (expect-eq !>(1.000) !>((parse-q "1.0")))
    (expect-eq !>(1.000) !>((parse-q "2")))
    (expect-eq !>(800) !>((parse-q "0.8")))
    (expect-eq !>(850) !>((parse-q "0.85")))
    (expect-eq !>(855) !>((parse-q "0.8555")))
    (expect-eq !>(0) !>((parse-q "0")))
    (expect-eq !>(0) !>((parse-q ".5")))
    (expect-eq !>(0) !>((parse-q "abc")))
    (expect-eq !>(0) !>((parse-q "")))
  ==
::
++  test-colors
  ;:  weld
    (expect-eq !>("#24466f") !>((hex-color 0x24.466f)))
    (expect-eq !>("#000000") !>((hex-color 0x0)))
    (expect-eq !>("#ef0123") !>((hex-color 0xab.cdef.0123)))
    ::  every sample tile from the design mock
    (expect-eq !>("#151514") !>((tile-ink 0xe6.dac6)))
    (expect-eq !>("#151514") !>((tile-ink 0x86.bbb2)))
    (expect-eq !>("#ffffff") !>((tile-ink 0x24.466f)))
    (expect-eq !>("#151514") !>((tile-ink 0xf2.c14e)))
    (expect-eq !>("#ffffff") !>((tile-ink 0x1f.3b30)))
    (expect-eq !>("#ffffff") !>((tile-ink 0x3d.3934)))
    (expect-eq !>("#151514") !>((tile-ink 0xc8.b9ee)))
    (expect-eq !>("#151514") !>((tile-ink 0xe9.a3a9)))
    (expect-eq !>("#ffffff") !>((tile-ink 0xd6.503c)))
  ==
::
++  test-text
  ;:  weld
    (expect-eq !>("1.2.0") !>((version-tape [1 2 0])))
    (expect-eq !>("harbor-zod") !>((anchor ~zod %harbor)))
    (expect-eq !>("quill-sampel-palnet") !>((anchor ~sampel-palnet %quill)))
    (expect-eq !>("H") !>((initial 'Harbor')))
    (expect-eq !>("Å") !>((initial 'Ångström')))
    (expect-eq !>("") !>((initial '')))
    (expect-eq !>("A") !>((initial 'A\09B')))
    (expect-eq !>("") !>((initial '\09AB')))
    (expect-eq !>("") !>((initial `@t`0x61ff)))
    (expect-eq !>("日") !>((initial '日本')))
    (expect-eq !>("🎉") !>((initial '🎉 party')))
    (expect-eq !>(~["a" "" "b"]) !>((split "a,,b" ',')))
    (expect-eq !>("a b") !>((strip "  a b\09 ")))
  ==
--
