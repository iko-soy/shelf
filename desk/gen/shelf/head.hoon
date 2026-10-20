::  set the raw HTML appended to the page's <head>, e.g. analytics
::
::    :shelf|head '<script defer src="https://…"></script>'
::    :shelf|head ''
::
::  It goes into the page unescaped. Escape ' as \' and \ as \\.
::
/-  shelf
:-  %say
|=  [* [html=@t ~] ~]
:-  %shelf-action
^-  action:shelf
[%head html]
