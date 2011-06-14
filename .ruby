--- 
spec_version: 1.0.0
replaces: []

loadpath: 
- lib
name: detroit
repositories: 
  public: http://github.com/proutils/detroit.git
conflicts: []

engine_check: []

title: Detroit
contact: Trans <transfire@gmail.com>
resources: 
  code: http://github.com/rubyworks/detroit
  mail: http://groups.google.com/rubyworks-mailinglist
  home: http://rubyworks.github.com/detroit
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
manifest: Manifest
version: 1.0.0
licenses: 
- GPL3
copyright: Copyright (c) 2007 Thomas Sawyer
authors: 
- Thomas Sawyer
organization: Rubyworks
description: Detroit is an advanced lifecycle build system. With Detroit, build tasks are user defined service instances tied to stops along a track. Whenever the detroit console command is run, a track is followed from beginning to designated destination.
summary: Software Production Mangement
created: 2007-10-10
