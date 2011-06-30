--- !ruby/object:Gem::Specification 
name: detroit
version: !ruby/object:Gem::Version 
  prerelease: 
  version: 0.1.0
platform: ruby
authors: 
- Thomas Sawyer
autorequire: 
bindir: bin
cert_chain: []

date: 2011-06-30 00:00:00 Z
dependencies: 
- !ruby/object:Gem::Dependency 
  name: facets
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
  name: pom
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
  name: qed
  prerelease: false
  requirement: &id003 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: "0"
  type: :development
  version_requirements: *id003
description: Detroit is an advanced lifecycle build system. With Detroit, build tasks are user defined service instances tied to stops along a track. Whenever the detroit console command is run, a track is followed from beginning to designated destination.
email: transfire@gmail.com
executables: 
- detroit
extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
- .ruby
- bin/detroit
- lib/detroit/application.rb
- lib/detroit/assembly.rb
- lib/detroit/config.rb
- lib/detroit/control.rb
- lib/detroit/core_ext.rb
- lib/detroit/custom.rb
- lib/detroit/dsl.rb
- lib/detroit/schedule.rb
- lib/detroit/service.rb
- lib/detroit/standard_assembly.rb
- lib/detroit/tool/core_ext/facets.rb
- lib/detroit/tool/core_ext/filetest.rb
- lib/detroit/tool/core_ext/shell_extensions.rb
- lib/detroit/tool/core_ext/to_actual_filename.rb
- lib/detroit/tool/core_ext/to_console.rb
- lib/detroit/tool/core_ext/to_list.rb
- lib/detroit/tool/core_ext/to_yamlfrag.rb
- lib/detroit/tool/core_ext/unfold_paragraphs.rb
- lib/detroit/tool/core_ext.rb
- lib/detroit/tool/email_utils.rb
- lib/detroit/tool/project_utils.rb
- lib/detroit/tool/shell_utils.rb
- lib/detroit/tool.rb
- lib/detroit.rb
- lib/detroit.yml
- qed/01_schedule/02_initialize.md
- qed/99_plugins/rdoc/rdoc-plugin.rdoc
- qed/99_plugins/rdoc/sample/Syckfile
- qed/99_plugins/rdoc/sample/lib/sandbox/.xxx
- qed/99_plugins/rdoc/sample/lib/sandbox/hello.rb
- qed/99_plugins/rdoc/sample/lib/sandbox/xxx.rb
- qed/99_plugins/rdoc/sample/lib/xxx/bye.rb
- qed/99_plugins/rdoc/sample/meta/name
- qed/99_plugins/rdoc/sample/meta/version
- qed/samples/example_project/.ruby
- qed/samples/example_project/Schedule
- qed/samples/example_project/lib/foo/.xxx
- qed/samples/example_project/lib/foo/hello.rb
- qed/samples/example_project/lib/foo/xxx/bye.rb
- qed/samples/example_project/lib/foo/xxx.rb
- qed/samples/example_project/meta/name
- qed/samples/example_project/meta/version
- qed/samples/example_schedule.rb
- HISTORY.rdoc
- README.rdoc
- GPL3.txt
- COPYING.rdoc
- EXAMPLE.md
homepage: http://rubyworks.github.com/detroit
licenses: 
- GPL3
post_install_message: 
rdoc_options: 
- --title
- Detroit API
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

rubyforge_project: detroit
rubygems_version: 1.8.2
signing_key: 
specification_version: 3
summary: Software Production Mangement
test_files: []

