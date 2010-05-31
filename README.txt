= ivy4r

* http://github.com/klaas1979/ivy4r/tree/master

== DESCRIPTION:

Apache Ivy dependency manager wrapper for ruby (see {Apache Ivy}[http://ant.apache.org/ivy/index.html] for more information).
Use {Apache Ivy}[http://ant.apache.org/ivy/index.html] via a ruby wrapper without the need to use Apache Ant.
The wrapper uses Antwrap[http://antwrap.rubyforge.org/] to interface with Ivy.

Includes a Extension for Buildr[http://buildr.apache.org/] and Rake[http://rake.rubyforge.org] to use
{Apache Ivy}[http://ant.apache.org/ivy/index.html] for dependency management.

== FEATURES/PROBLEMS:

Supports most standard Ivy Ant targets via Antwrap. Provides a caching feature so that long running ivy tasks
like resolve can be cached and are not rerun for local builds. For more information about caching see the History.txt
and checkout the source of buildr/ivy_extension.rb and rake/ivy_extension.rb.

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

=== Caching of Ivy results:
For Buildr the targets ivy:enable_result_cache, ivy:disable_result_cache and ivy:clean_result_cache have been added.
Additionally the result cache can be enabled via the build.yaml or the global buildr settings.yaml by setting
the variable "ivy: caching.enabled: true".

For Rake the targets ivy:enable_result_cache, ivy:disable_result_cache and ivy:clean_result_cache have been added as
well. For Rake there is no other way to enable the caching beside this targets.

== Notes about usage and testing:
A few information how this project is used and what parts are well tested and what parts are nearly never used.

=== Buildr extension:
The buildr extension is tested only on projects with a single ivy.xml, the multi ivy.xml file support was added
but was never tested extensively!

=== Rake extension:
Note that the rake extension is only test in JRuby Rails projects to publish a java WAR file into the repository.
It does not offer as many features as the buildr extension.

== SYNOPSIS:

ivy4r plain:
  To init a new Ivy4r instance set the ANT_HOME and the Ivy lib dir
    ivy4r = Ivy4r.new
    ivy4r.ant_home = 'PATH TO YOUR ANTHOME'
    ivy4r.lib_dir = 'PATH TO IVY LIB DIR'
  as an alternative to setting the ANT_HOME you can set an +Antwrap+ instance directly:
    ivy4r.ant = Buildr.ant('ivy')
    
buildr:
  TODO add buildr example

rake:
  TODO add rake example

== REQUIREMENTS:

Plain ivy4r:
* Installed Apache Ant, to call Ivy via Antwrap
* Ivy and dependencies in a single directory. Dependencies depends on used features, see the ivy homepage for more information.
* JRuby is well tested, MRI support has been added with version 0.11.0 so use it at your own risk.
* Rake to use the rake extension
* Buildr to use the buildr extension

== INSTALL:

You can use gemcutter to install
  sudo gem install ivy4r

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
