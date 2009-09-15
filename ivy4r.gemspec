# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ivy4r}
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Klaas Prause"]
  s.date = %q{2009-09-15}
  s.default_executable = %q{ivy4r}
  s.description = %q{Apache Ivy dependency manager wrapper for ruby (see {Apache Ivy}[http://ant.apache.org/ivy/index.html] for more information).
Use {Apache Ivy}[http://ant.apache.org/ivy/index.html] via a ruby wrapper without the need to use Apache Ant.
The wrapper uses Antwrap[http://antwrap.rubyforge.org/] to interface with Ivy.

Includes a Extension for Buildr[http://buildr.apache.org/] to use {Apache Ivy}[http://ant.apache.org/ivy/index.html]
for dependency management.}
  s.email = ["klaas.prause@googlemail.com"]
  s.executables = ["ivy4r"]
  s.extra_rdoc_files = [
    "History.txt",
     "Manifest.txt",
     "README.txt"
  ]
  s.files = [
    "History.txt",
     "Manifest.txt",
     "README.txt",
     "Rakefile",
     "bin/ivy4r",
     "lib/buildr/ivy_extension.rb",
     "lib/ivy/artifactproperty.rb",
     "lib/ivy/artifactreport.rb",
     "lib/ivy/buildlist.rb",
     "lib/ivy/buildnumber.rb",
     "lib/ivy/cachepath.rb",
     "lib/ivy/cleancache.rb",
     "lib/ivy/configure.rb",
     "lib/ivy/findrevision.rb",
     "lib/ivy/info.rb",
     "lib/ivy/listmodules.rb",
     "lib/ivy/makepom.rb",
     "lib/ivy/publish.rb",
     "lib/ivy/report.rb",
     "lib/ivy/resolve.rb",
     "lib/ivy/retrieve.rb",
     "lib/ivy/settings.rb",
     "lib/ivy/target.rb",
     "lib/ivy/targets.rb",
     "lib/ivy4r.rb",
     "lib/rake/ivy_extension.rb",
     "test/buildlist/p1/buildfile",
     "test/buildlist/p1/ivy.xml",
     "test/buildlist/sub/p2/buildfile",
     "test/buildlist/sub/p2/ivy.xml",
     "test/buildlist/sub/p3/buildfile",
     "test/buildlist/sub/p3/ivy.xml",
     "test/ivy/ivysettings.xml",
     "test/ivy/ivytest.xml",
     "test/ivy/test_target.rb",
     "test/ivy/test_targets.rb",
     "test/test_ivy4r.rb"
  ]
  s.homepage = %q{http://github.com/klaas1979/ivy4r/tree/master}
  s.rdoc_options = ["--main", "README.txt", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{hamburgrb}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Apache Ivy dependency manager wrapper for ruby (see {Apache Ivy}[http://ant.apache.org/ivy/index.html] for more information)}
  s.test_files = [
    "test/test_ivy4r.rb",
     "test/ivy/test_target.rb",
     "test/ivy/test_targets.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<Antwrap>, [">= 0.7.0"])
      s.add_runtime_dependency(%q<ivy4r-jars>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<facets>, [">= 2.5.2"])
      s.add_development_dependency(%q<hoe>, [">= 2.2.0"])
    else
      s.add_dependency(%q<Antwrap>, [">= 0.7.0"])
      s.add_dependency(%q<ivy4r-jars>, [">= 1.0.0"])
      s.add_dependency(%q<facets>, [">= 2.5.2"])
      s.add_dependency(%q<hoe>, [">= 2.2.0"])
    end
  else
    s.add_dependency(%q<Antwrap>, [">= 0.7.0"])
    s.add_dependency(%q<ivy4r-jars>, [">= 1.0.0"])
    s.add_dependency(%q<facets>, [">= 2.5.2"])
    s.add_dependency(%q<hoe>, [">= 2.2.0"])
  end
end
