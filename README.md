# Detroit

[Website](http://rubyworks.github.io/detroit) /
[Report Issue](http://github.com/rubyworks/detroit/issues) /
[Development](http://github.com/rubyworks/detroit)

[![Build Status](https://secure.travis-ci.org/rubyworks/detroit.png)](http://travis-ci.org/rubyworks/detroit) 
[![Gem Version](https://badge.fury.io/rb/detroit.png)](http://badge.fury.io/rb/detroit) &nbsp; &nbsp;
[![Flattr Me](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/324911/Rubyworks-Ruby-Development-Fund)


## About

Detroit is a software production management aid, aka a *build tool*.
Detroit utilizes a life-cycle methodology to help developers
prepare and release software in a clear, repeatable, and linear fashion.
While written in, and therefore well-suited to Ruby development, Detroit
can be used for any language and production requirements.


## How It Works

Detroit defines development processions call *assemblies* which consist of
a set of production *lines* each with a series of named *stations*, or *stops*.
Developers attach work elements to stations by creating configuring tool
instances in a project's Toolchain file. Toolchain files are written
in either YAML or a Ruby DSL.

For example, a RubyForge tool can be configured:

    rubyforge:
      tool: Rubyforge
      sitemap:
        site: <%= name %>
      active: true

As this example demonstrates, tool configurations can draw on project
metadata via ERB embedded tags. Detroit gathers this information using
[.index](http://dotruby.github.com/indexer) file, but the data source
can be customized to meet the needs of different projects. (For instance,
for Ruby projects, if no .index file is found, Detroit will attempt get the
information from a .gemspec file.)

With tool configuration and metadata in place, using Detroit is simply
a matter of passing a stop to the `detroit` command. 

    $ detroit document

The use of lines may seem constrictive to users of tools like Rake, but
there is a benefit to this approach. It helps ensure a project is 
always up-to-date and in-sync --that no necessary steps are missed.
Detroit standard asembly has two lines. The most significant of which is
main line which entails a route with ordred stops:

    prepare     # prepare services and ensure requirements
    generate    # code generation
    compile     # compile source code
    test        # run tests and/or specifications
    analyze     # run code analysis
    document    # generate documentation
    package     # create packages
    verify      # post package verification (eg. integration tests)
    install     # install package locally
    publish     # publish website/documentation
    release     # release packages
    deploy      # deply system to servers
    promote     # tell the world about you awesome work

The second line is maintainence line which consits of three stops:

    reset       # mark build files as out-of-date
    clean       # remove minor build files
    purge       # remove all build files

Where reset marks generated files out-of-date, clean removes temporary
products and purge removes all generated prodcuts.

To refine control over the build process, tool instances can be grouped into
different *tracks*. For example, a Github gh-pages tool might be configured
to be on a `site` track, so publishing a project's website only occurs if
the `site` track is specified along with `publish` stop.

    $ detroit site:publish

Please see http://rubyworks.github.com/detroit for more details on how to
use Detroit, including the creation of tracks, stops and tool plugins.
Also try the `--help` option to see the detroit command's help
information.


## Install

Detroit can, of course, be installed via RubyGems:

    $ gem install detroit

Once installed, developers need to also install the specific plugins
for the tools to be used. For example,

    $ gem install detroit-github
    $ gem install detroit-minitest
    $ gem install detroit-yard

If using Bundler, just add these to the project's Gemfile instead.


## Issues

All in all, Detroit works well. There are some rough edges with regards
to the plugins, so from time to time you might run into an odd error.
Ususally it just means a tool confirguraiton needs adjustment.

Please note, Windows support has not been considered at all. While we see
no specific reason it should not work, there may well be issues we have not
considered since we do not use Windows. If you are Windows user and give
Detroit a try please let us know of any issues you encounter.


## History

Detroit is actaully a fork of Reap v10, and was called Syckle for a number
of years as it matured. It represents many years of design considerations
(and reconsiderations) that evolved Reap from its simple Rake extension
origins (which pre-date Hoe) to the life-cycle system it is today.


## Legal

Copyright (c) 2007 Rubyworks (GPL-3.0 License)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See LICENSE.txt for details.

