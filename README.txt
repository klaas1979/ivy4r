= ivy4r

* http://github.com/klaas1979/ivy4r/tree/master
* http://hamburgrb.rubyforge.org/

== DESCRIPTION:

Apache Ivy dependency manager wrapper for ruby (see {Apache Ivy}[http://ant.apache.org/ivy/index.html] for more information).
Use {Apache Ivy}[http://ant.apache.org/ivy/index.html] via a ruby wrapper without the need to use Apache Ant.
The wrapper uses Antwrap[http://antwrap.rubyforge.org/] to interface with Ivy.

Includes a Extension for Buildr[http://buildr.apache.org/] to use {Apache Ivy}[http://ant.apache.org/ivy/index.html]
for dependency management.

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

  To init a new Ivy4r instance set the ANT_HOME and the Ivy lib dir
    ivy4r = Ivy4r.new
    ivy4r.ant_home = 'PATH TO YOUR ANTHME'
    ivy4r.lib_dir = 'PATH TO IVY LIB DIR'
  as an alternative to setting the ANT_HOME you can set an +Antwrap+ instance directly:
    ivy4r.ant = Buildr.ant('ivy')

== REQUIREMENTS:

* Installed Apache Ant, to call Ivy via Antwrap
* Ivy and dependencies in a single directory. Dependencies depends on used features, see the ivy homepage for more information.

== INSTALL:

* sudo gem install ivy4r
* sudo gem install klaas1979-ivy4r (from github to get the development stuff)

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
