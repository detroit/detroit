--- !ruby/object:Gem::Specification 
name: redline
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

date: 2011-05-27 00:00:00 Z
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
description: Redline is an advanced lifecycle-oriented build system. With Redline build tasks are user define service instances tied to stops along a line, or track. Whenever the redline console command is run a track is followed from beginning to designated destination.
email: transfire@gmail.com
executables: 
- redline
extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
- .ruby
- bin/redline
- lib/plugins/sow/redline/README
- lib/plugins/sow/redline/Sowfile
- lib/plugins/sow/redline/template/PROFILE
- lib/plugins/sow/redline/template/REQUIRE
- lib/plugins/sow/redline/template/Syckfile
- lib/plugins/sow/redline/template/VERSION
- lib/redline/application.rb
- lib/redline/basic_object.rb
- lib/redline/cli.rb
- lib/redline/config/ruby_parser.rb
- lib/redline/config/yaml_parser.rb
- lib/redline/config.rb
- lib/redline/core_ext.rb
- lib/redline/plugins/announce.rb
- lib/redline/plugins/custom.rb
- lib/redline/plugins/dnote.rb
- lib/redline/plugins/extconf.rb
- lib/redline/plugins/gem.rb
- lib/redline/plugins/grancher.rb
- lib/redline/plugins/rdoc.rb
- lib/redline/plugins/ri.rb
- lib/redline/plugins/rspec.rb
- lib/redline/plugins/script.rb
- lib/redline/plugins/stats.rb
- lib/redline/plugins/syntax.rb
- lib/redline/plugins/testrb.rb
- lib/redline/plugins/turn.rb
- lib/redline/plugins/yard.rb
- lib/redline/service.rb
- lib/redline/shell/email.rb
- lib/redline/track.rb
- lib/redline/tracks/attn.rb
- lib/redline/tracks/main.rb
- lib/redline/tracks/site.rb
- lib/redline.rb
- lib/redline.yml
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
- test/sample/Redfile
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
- EXAMPLE.rdoc
homepage: http://rubyworks.github.com/redline
licenses: 
- GPL3
post_install_message: 
rdoc_options: 
- --title
- Redline API
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

rubyforge_project: redline
rubygems_version: 1.8.2
signing_key: 
specification_version: 3
summary: Lifecycle-oriented build tool
test_files: []

