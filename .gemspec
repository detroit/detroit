--- !ruby/object:Gem::Specification 
name: pitstop
version: !ruby/object:Gem::Version 
  hash: 23
  prerelease: 
  segments: 
  - 1
  - 0
  - 0
  version: 1.0.0
platform: ruby
authors: 
- Thomas Sawyer
autorequire: 
bindir: bin
cert_chain: []

date: 2011-06-01 00:00:00 Z
dependencies: 
- !ruby/object:Gem::Dependency 
  name: redtools
  prerelease: false
  requirement: &id001 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 3
        segments: 
        - 0
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
        hash: 3
        segments: 
        - 0
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
        hash: 3
        segments: 
        - 0
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
        hash: 3
        segments: 
        - 0
        version: "0"
  type: :development
  version_requirements: *id004
description: Pitstop is an advanced life-cycle build system. With Pitstop, build tasks are user defined service instances tied to stops along a track. Whenever the pistop console command is run, a track is followed from beginning to designated destination.
email: transfire@gmail.com
executables: 
- pitstop
extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
- .ruby
- bin/pitstop
- lib/pitstop/application.rb
- lib/pitstop/config/ruby_parser.rb
- lib/pitstop/config/yaml_parser.rb
- lib/pitstop/config.rb
- lib/pitstop/control.rb
- lib/pitstop/core_ext.rb
- lib/pitstop/dsl.rb
- lib/pitstop/pitfile.rb
- lib/pitstop/plugins/custom.rb
- lib/pitstop/plugins/dnote.rb
- lib/pitstop/plugins/email.rb
- lib/pitstop/plugins/extconf.rb
- lib/pitstop/plugins/gem.rb
- lib/pitstop/plugins/grancher.rb
- lib/pitstop/plugins/rdoc.rb
- lib/pitstop/plugins/ri.rb
- lib/pitstop/plugins/rspec.rb
- lib/pitstop/plugins/script.rb
- lib/pitstop/plugins/stats.rb
- lib/pitstop/plugins/syntax.rb
- lib/pitstop/plugins/testrb.rb
- lib/pitstop/plugins/turn.rb
- lib/pitstop/plugins/yard.rb
- lib/pitstop/service.rb
- lib/pitstop/shell/email.rb
- lib/pitstop/track.rb
- lib/pitstop/tracks/attn.rb
- lib/pitstop/tracks/main.rb
- lib/pitstop/tracks/site.rb
- lib/pitstop.rb
- lib/pitstop.yml
- lib/plugins/sow/redline/README
- lib/plugins/sow/redline/Sowfile
- lib/plugins/sow/redline/template/PROFILE
- lib/plugins/sow/redline/template/REQUIRE
- lib/plugins/sow/redline/template/Syckfile
- lib/plugins/sow/redline/template/VERSION
- qed/pitfile/Pitfile.rb
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
homepage: http://rubyworks.github.com/pitstop
licenses: 
- GPL3
post_install_message: 
rdoc_options: 
- --title
- Pitstop API
- --main
- README.rdoc
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
requirements: []

rubyforge_project: pitstop
rubygems_version: 1.8.2
signing_key: 
specification_version: 3
summary: Life-cycle build tool
test_files: []

