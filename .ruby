--- 
name: syckle
company: RubyWorks
title: Syckle
contact: Trans <transfire@gmail.com>
requires: 
- group: []

  name: facets
  version: 0+
- group: []

  name: path
  version: 0+
- group: []

  name: gemdo
  version: 0+
- group: []

  name: plugin
  version: 0+
- group: 
  - test
  name: qed
  version: 0+
resources: 
  repository: http://github.com/proutils/syckle.git
  home: http://proutils.github.com/syckle
pom_verison: 1.0.0
manifest: 
- .ruby
- bin/syckle
- lib/plugins/sow/syckle/README
- lib/plugins/sow/syckle/Sowfile
- lib/plugins/sow/syckle/template/PROFILE
- lib/plugins/sow/syckle/template/REQUIRE
- lib/plugins/sow/syckle/template/Syckfile
- lib/plugins/sow/syckle/template/VERSION
- lib/plugins/syckle/autotools.rb
- lib/plugins/syckle/custom.rb
- lib/plugins/syckle/email.rb
- lib/plugins/syckle/excellent.rb
- lib/plugins/syckle/gemcutter.rb
- lib/plugins/syckle/grancher.rb
- lib/plugins/syckle/rcov.rb
- lib/plugins/syckle/rdoc.rb
- lib/plugins/syckle/ridoc.rb
- lib/plugins/syckle/rspec.rb
- lib/plugins/syckle/rubyprof.rb
- lib/plugins/syckle/script.rb
- lib/plugins/syckle/stats.rb
- lib/plugins/syckle/syntax.rb
- lib/plugins/syckle/testrb.rb
- lib/plugins/syckle/turn.rb
- lib/plugins/syckle/yard.rb
- lib/syckle/application.rb
- lib/syckle/cli.rb
- lib/syckle/config.rb
- lib/syckle/core_ext.rb
- lib/syckle/cycles/attn.rb
- lib/syckle/cycles/main.rb
- lib/syckle/cycles/site.rb
- lib/syckle/cycles.rb
- lib/syckle/io.rb
- lib/syckle/log.rb
- lib/syckle/package.yml
- lib/syckle/profile.yml
- lib/syckle/script.rb
- lib/syckle/service.rb
- lib/syckle/shell/email.rb
- lib/syckle/shell.rb
- lib/syckle.rb
- test/fn/rdoc/rdoc-plugin.rdoc
- test/fn/rdoc/sample/Syckfile
- test/fn/rdoc/sample/lib/sandbox/.xxx
- test/fn/rdoc/sample/lib/sandbox/hello.rb
- test/fn/rdoc/sample/lib/sandbox/xxx.rb
- test/fn/rdoc/sample/lib/xxx/bye.rb
- test/fn/rdoc/sample/meta/name
- test/fn/rdoc/sample/meta/version
version: 1.0.0
copyright: Copyright (c) 2007 Thomas Sawyer
licenses: 
- Apache 2.0
description: Syckle is an advanced life-cycle based build system.
summary: Advanced life-cycle build tool
authors: 
- Thomas Sawyer
created: 2007-10-10
