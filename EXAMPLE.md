= EXAMPLE REDFILE

== RUBY FORMAT

Ruby-based redfiles are written with the name of the service
as a capitalized method followed by an optional name for the particular
service instance and then a block of settings. If no instance name
is given, the name defaults to the name of the service itself downcased.
Settings are simply method calls followed by the value. They
can be nested with additional blocks which define Hash values.

  Announce   mailto: "ruby-talk@ruby-lang.org",
             active: true

  Announce :myself,
             mailto: "transfire@gmail.com",
             active: true

  Gem        types:  ['gem'],
             spec:   false,
             active: true

  DNote      priority: -1,
             active:   true

  RI         exclude: [],
             active:  true

  RDoc       include: [ 'lib', '[A-Z]*' ],
             exclude: [ 'Redfile' ]

  Stats      priority: -1
             active:   true

  Testrb     active: true

  Rubyforge  sitemap: {
               site: 'example'
             }
             active: false

== Or 

  service :announce
    set :mailto, "ruby-talk@ruby-lang.org"
    set :active, true
  end

  service :myself do
    set :type,   :Announce
    set :mailto, "transfire@gmail.com"
    set :active, true
  end

  service :gem do
    set :spec,   false
    set :active, true
  end

  service :dnote do
    set :priority, -1
    set :active, true
  end

  service :ri do
    set :exclude, []
    set :active,  true
  end

  service :rdoc do
    include: [ 'lib', '[A-Z]*' ],
    exclude: [ 'Redfile' ]
  end

  service :stats do
    set :priority, -1
    set :active,   true
  end

  service :testrb do
    set :active, true
  end

  service :rubyforge do
    set :sitemap, {
      site 'example'
    }
    set :active, false
  end

The setting +active+ defaults to +true+ if not given, so is not strictly
needed in the above example, but it is convenient to have in case you
ever need to deactivate a service temporarily --more convenient than
remarking out the whole section.

Alternately the Ruby format supports yield notation too, e.g.

  service :myself do |s|
    s.type   = :Announce
    s.mailto = "transfire@gmail.com"
    sactive  = true
  end


== YAML FORMAT

The YAML format is essentailly the same as the Ruby format except that
the main key provides the service instance name and the service is an
setting which defaults the name. Unlike the Ruby format the service names
do not have to be capitalized. Also, notic the start document indicator
(<code>---</code>). The indeicator is required for Redline to recognize the redfile
as YAML, rather than Ruby.

  ---
  announce:
    mailto: "transfire@gmail.com"
    active: true

  myself:
    service: Announce
    mailto:  "transfire@gmail.com"
    active:  true

  gem:
    types:    ['gem']
    autospec: false
    active:   true

  dnote:
    priority: -1
    active:   true

  rdoc:
    include: [ lib, '[A-Z]*' ]
    exclude: [ Redfile ]

  ri:
    exclude: []
    active:  true

  stats:
    priority: -1
    active:   true

  testrb:
    active: true

  rubyforge:
    service: forge
    sitemap:
      site: <% name %>
    active: false

As we can see in the last entry, the YAML format also supports ERB and provides
access to project metadata via the ERB's binding.

With the Ruby format it is easy enough to load external Redline plugins using
standard +require+ and +load+ methods. The YAML format's support of ERB
can be used to achieve the same effect.

  ---
  <% require 'some/redline/plugin' %>


Which format you use is strictly a regard of your personal preference.
