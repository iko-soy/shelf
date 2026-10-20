::  set the raw HTML appended to the end of the page's <body>
::
::    :shelf|body '<script async src="https://…"></script>'
::    :shelf|body ''
::
::  It goes into the page unescaped. Escape ' as \' and \ as \\.
::
/-  shelf
:-  %say
|=  [* [html=@t ~] ~]
:-  %shelf-action
^-  action:shelf
[%body html]
