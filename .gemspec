--- !ruby/object:Gem::Specification 
name: promenade
version: !ruby/object:Gem::Version 
  prerelease: 
  version: 1.0.0
platform: ruby
authors: 
- Thomas Sawyer
autorequire: 
bindir: bin
cert_chain: []

date: 2011-06-13 00:00:00 Z
dependencies: 
- !ruby/object:Gem::Dependency 
  name: redtools
  prerelease: false
  requirement: &id001 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: "0"
  type: :runtime
  version_requirements: *id001
- !ruby/object:Gem::Dependency 
  name: facets
  prerelease: false
  requirement: &id002 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: "0"
  type: :runtime
  version_requirements: *id002
- !ruby/object:Gem::Dependency 
  name: pom
  prerelease: false
  requirement: &id003 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: "0"
  type: :runtime
  version_requirements: *id003
- !ruby/object:Gem::Dependency 
  name: qed
  prerelease: false
  requirement: &id004 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: "0"
  type: :development
  version_requirements: *id004
description: Promenade is an advanced lifecycle build system. With Promenade, build tasks are user defined service instances tied to stops along a track. Whenever the promenade console command is run, a track is followed from beginning to designated destination.
email: transfire@gmail.com
executables: 
- promenade
extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
- .ruby
- bin/promenade
- lib/plugins/sow/pitstop/README
- lib/plugins/sow/pitstop/Sowfile
- lib/plugins/sow/pitstop/template/PROFILE
- lib/plugins/sow/pitstop/template/REQUIRE
- lib/plugins/sow/pitstop/template/Syckfile
- lib/plugins/sow/pitstop/template/VERSION
- lib/promenade/application.rb
- lib/promenade/circuit.rb
- lib/promenade/config.rb
- lib/promenade/control.rb
- lib/promenade/core_ext.rb
- lib/promenade/dsl.rb
- lib/promenade/plugins/custom.rb
- lib/promenade/plugins/dnote.rb
- lib/promenade/plugins/email.rb
- lib/promenade/plugins/extconf.rb
- lib/promenade/plugins/gem.rb
- lib/promenade/plugins/grancher.rb
- lib/promenade/plugins/qed.rb
- lib/promenade/plugins/rdoc.rb
- lib/promenade/plugins/ri.rb
- lib/promenade/plugins/rspec.rb
- lib/promenade/plugins/script.rb
- lib/promenade/plugins/stats.rb
- lib/promenade/plugins/syntax.rb
- lib/promenade/plugins/testrb.rb
- lib/promenade/plugins/turn.rb
- lib/promenade/plugins/vclog.rb
- lib/promenade/plugins/yard.rb
- lib/promenade/schedule.rb
- lib/promenade/service.rb
- lib/promenade/standard_circuit.rb
- lib/promenade.rb
- lib/promenade.yml
- qed/promenade/Pitfile.rb
- qed/rdoc/rdoc-plugin.rdoc
- qed/rdoc/sample/Syckfile
- qed/rdoc/sample/lib/sandbox/.xxx
- qed/rdoc/sample/lib/sandbox/hello.rb
- qed/rdoc/sample/lib/sandbox/xxx.rb
- qed/rdoc/sample/lib/xxx/bye.rb
- qed/rdoc/sample/meta/name
- qed/rdoc/sample/meta/version
- test/case_rdoc.rb
- test/sample/.ruby
- test/sample/Pitfile
- test/sample/lib/foo/.xxx
- test/sample/lib/foo/hello.rb
- test/sample/lib/foo/xxx/bye.rb
- test/sample/lib/foo/xxx.rb
- test/sample/meta/name
- test/sample/meta/version
- HISTORY.rdoc
- README.rdoc
- GPL3.txt
- COPYING.rdoc
- EXAMPLE.md
homepage: http://rubyworks.github.com/promenade
licenses: 
- GPL3
post_install_message: 
rdoc_options: 
- --title
- Promenade API
- --main
- README.rdoc
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
requirements: []

rubyforge_project: promenade
rubygems_version: 1.8.2
signing_key: 
specification_version: 3
summary: Software Production Mangement
test_files: []

