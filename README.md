# Detroit

[Website](http://rubyworks.github.com/detroit) /
[Report Issue](http://github.com/rubyworks/detroit/issues) /
[Development](http://github.com/rubyworks/detroit)

[![Build Status](https://secure.travis-ci.org/rubyworks/detroit.png)](http://travis-ci.org/rubyworks/detroit) 
[![Gem Version](https://badge.fury.io/rb/detroit.png)](http://badge.fury.io/rb/detroit) &nbsp; &nbsp;
[![Flattr Me](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/324911/Rubyworks-Ruby-Development-Fund)


## About

Detroit is a software production management aid for Ruby developers.
Detroit utilizes a life-cycle methodology to help developers prepare and
release Ruby software in a clear, repeatable, linear fashion.


## How It Works

Detroit defines development processions which consist of a set of named 
production _lines_, or _tracks_, each with a series of named _stations_,
or _stops_. Developers attach work elements to stations by configuring
service instances in a project's Schedule or *.schedule files. Schedules
are written in either YAML or a Ruby DSL.

For example, a RubyForge service can be defined:

    rubyforge:
      service: Rubyforge
      sitemap:
        site: <%= name %>
      active: true

As this example demonstrates, service configurations can draw on project
metadata via ERB embedded tags. Detroit gathers this information using
[.index](http://dotruby.github.com/indexer), but the data source can be
easily customized to meet the needs of different projects.

With service configuration and metadata in place, using Detroit is simply
a matter of passing a line name and stop to the +detroit+ command line
tool. For example,

    $ detroit main:document

The track name and its stop are separated by a colon. This command
would run every stop on the +main+ track, in order, until it completes
the +document+ stop. Since +main+ is the default track, we can acheive
the same effect without specifying it.

    $ detroit document

The use of tracks may seem constrictive to users of tools like Rake, but
there is a benefit to this approach. It helps ensure a project is 
always up-to-date and in-sync --that no necessary steps are missed.
Detroit includes three tracks out of the box. The most significant of
which is +main+ which entails a route with ordred stops:

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

All tracks also have a maintainence subtrack which consits of three stops:

    reset       # mark build files as out-of-date
    clean       # remove minor build files
    purge       # remove all build files

Where reset marks generated files out-of-date, clean removes temporary
products and purge removes all generated prodcuts.

In additon to `main`, Detroit includes `site` and `attn` tracks which are used
to generate and publish a project's website, and make project announcements
respectively. They are simply useful subsets of the +main+ track.

Please see http://rubyworks.github.com/detroit for more details on how to
use Detroit, including the creation of custom tracks, stops and service plugins.
Also try the `--help` option to see the detroit command's help
information.


## Install

Detroit can, of course, be installed via RubyGems:

    $ gem install detroit

We no longer recommend it, but Detroit can also be installed the
old-fashion way by downloading the .tar.gz package and using
Ruby Setup (See http://setup.rubyforge.org).

    $ tar -xvzf detroit-1.0.0.tar.gz
    $ cd detroit-1.0.0
    $ sudo setup.rb

Ruby Setup is stand-alone version of the original setup.rb script.


## Issues

All in all, Detroit works well. There are some rough edges with regards
to the built-in service plugins, so from time to time you might run into
an odd error. Ususally it just means a service confirguraiton needs 
adjustment.

Please note, Windows support has not been considered at all. While I do
not see any specific reason it should not work, there may well be issues
I have not considered since I do not use Windows. If you are Windows user
and give Detroit a try please let us know of any issues you encounter.


## History

Detroit is actaully the offspring of Reap v10, and was called Syckle for 
a number of years as it matured. It represents many years of design considerations
(and reconsiderations) that evolved Reap from its simple Rake extension origins,
which pre-dated Hoe, to the life-cycle system it is today.


## Legal

Detroit

Copyright (c) 2007 Rubyworks

(GPL-3.0 License)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See LICENSE.txt for details.

