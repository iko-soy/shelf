::  shelf: owner configuration for the %shelf agent
::
|%
::  $action: set raw HTML the page appends to its <head> or <body>
::
::    Meant for analytics snippets and the like. It is inserted as-is,
::    unescaped. '' clears it.
::
+$  action
  $%  [%head html=@t]
      [%body html=@t]
  ==
--
