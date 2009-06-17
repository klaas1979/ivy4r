= ivy4r

* http://github.com/klaas1979/ivy4r/tree/master

== DESCRIPTION:

Apache Ivy dependency manager wrapper for ruby (see http://ant.apache.org/ivy/index.html for more information).Use Ivy via a ruby wrapper without the need to use Apache Ant.
The wrapper uses Antwrap (see http://antwrap.rubyforge.org/) to interface with Ivy.

== FEATURES/PROBLEMS:

Supports most standard Ivy Ant targets via Antwrap.

=== Supported Ivy targets:
* info
* settings
* configure
* cleancache
* buildnumber
* findrevision
* cachepath
* artifactreport
* resolve
* makepom
* retrieve
* publish
* artifactproperty
* report
* buildlist
* deliver
* install
* repreport

=== Currently not working Ivy targets:
* listmodules

=== Ivy targets that need to be implemented:
* deliver
* install
* repreport

=== Unsupported Ivy Targets (they make no sense for the wrapper):
* cachefileset
* var

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* Installed Apache Ant, to call Ivy via Antwrap.
* Ivy and dependencies in a single directory. Dependencies depends on used features, see the ivy homepage for more information.

== INSTALL:

* sudo gem install ivy4r

== LICENSE:

(The MIT License)

Copyright (c) 2009 blau Mobilfunk GmbH

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
