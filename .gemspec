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

date: 2011-05-26 00:00:00 Z
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
  name: plugin
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
  type: :runtime
  version_requirements: *id004
- !ruby/object:Gem::Dependency 
  name: qed
  prerelease: false
  requirement: &id005 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 3
        segments: 
        - 0
        version: "0"
  type: :development
  version_requirements: *id005
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
- lib/plugins/redline/announce.rb
- lib/plugins/redline/custom.rb
- lib/plugins/redline/dnote.rb
- lib/plugins/redline/extconf.rb
- lib/plugins/redline/gem.rb
- lib/plugins/redline/grancher.rb
- lib/plugins/redline/rdoc.rb
- lib/plugins/redline/ri.rb
- lib/plugins/redline/rspec.rb
- lib/plugins/redline/script.rb
- lib/plugins/redline/stats.rb
- lib/plugins/redline/syntax.rb
- lib/plugins/redline/testrb.rb
- lib/plugins/redline/turn.rb
- lib/plugins/redline/yard.rb
- lib/plugins/sow/redline/README
- lib/plugins/sow/redline/Sowfile
- lib/plugins/sow/redline/template/PROFILE
- lib/plugins/sow/redline/template/REQUIRE
- lib/plugins/sow/redline/template/Syckfile
- lib/plugins/sow/redline/template/VERSION
- lib/redline/application.rb
- lib/redline/basic_object.rb
- lib/redline/cli.rb
- lib/redline/config.rb
- lib/redline/core_ext.rb
- lib/redline/io.rb
- lib/redline/log.rb
- lib/redline/script.rb
- lib/redline/service/domain.rb
- lib/redline/service.rb
- lib/redline/shell/email.rb
- lib/redline/shell.rb
- lib/redline/tool.rb
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
- HISTORY.rdoc
- README.rdoc
- GPL3.txt
- COPYING.rdoc
homepage: http://proutils.github.com/redline
licenses: 
- Dual GPL3
- Dual GPL3
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

