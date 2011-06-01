--- 
spec_version: 1.0.0
replaces: []

loadpath: 
- lib
name: pitstop
repositories: 
  public: http://github.com/proutils/pitstop.git
conflicts: []

engine_check: []

title: Pitstop
contact: Trans <transfire@gmail.com>
resources: 
  code: http://github.com/rubyworks/pitstop
  mail: http://groups.google.com/rubyworks-mailinglist
  home: http://rubyworks.github.com/pitstop
maintainers: []

requires: 
- group: []

  name: redtools
  version: 0+
- group: []

  name: facets
  version: 0+
- group: []

  name: pom
  version: 0+
- group: 
  - test
  name: qed
  version: 0+
manifest: MANIFEST
version: 1.0.0
licenses: 
- GPL3
copyright: Copyright (c) 2007 Thomas Sawyer
authors: 
- Thomas Sawyer
organization: Rubyworks
description: Pitstop is an advanced life-cycle build system. With Pitstop, build tasks are user defined service instances tied to stops along a track. Whenever the pistop console command is run, a track is followed from beginning to designated destination.
summary: Life-cycle build tool
created: 2007-10-10
