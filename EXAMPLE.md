# Detroit

Detroit's main configuration file is called a *toolchain*. Toolchains define the 
specific *tool instances* that a project will utilize. 

Toolchains can be written in a few different formats thanks to the flexibility
of Ruby. All formats are equivalent. Which format you use is strictly a regard
of your personal preference.

## Ruby-based Toolchain Scripts

### Tool Method Notation

Traditionally a Ruby-based assembly file is dominated by calls to the `tool`
method with an optional service instance name and a setter block.

```ruby
  tool :myself do |s|
    s.type   = :Announce
    s.mailto = "transfire@gmail.com"
    s.active = true
  end

  tool :rdoc do |r|
    r.include = [ 'lib', '[A-Z]*' ]
    r.exclude = [ 'Gemfile' ]
  end
```

If no `type` setting is given, it is assumed to be same as the tool instance name.
In the above example `rdoc` is taken to be both the tool desired and the name of
this particular instance.

A few years ago, Sinatra came along and popularized the use of the `#set` method.
A simple addition to Detroit's assembly file parser now allows for this arguably 
cleaner notation:

```ruby
  tool :myself do
    set :type, :Announce
    set :mailto, "transfire@gmail.com"
    set :priority, -1
    set :active, true
  end

  tool :rdoc do
    set :include, [ 'lib', '[A-Z]*' ]
    set :exclude, [ 'Gemfile' ]
  end
```

The `#set` method also allows for nested set blocks to define hash values.

```ruby
  service :rubyforge do
    set :sitemap do
      set :site, name
    end
    set :active, false
  end
```

The setting `active` defaults to `true` if not given, so is not strictly
needed in the above examples, but it is convenient to have in case you
ever need to deactivate a service temporarily --more convenient than
remarking out a whole section. 

Almost all options have standard defaults so it is often possible for a service
definition to be written as simply as:

```ruby
  tool :rdoc
```

### Tool Name Notation

Thanks to some straight-forward meta-programming, a Ruby-based toolchain file can
be written in a more concise notation by using the name of the tool class as a
method. This can be followed by a settings block, as with the above examples,
or passed a *settings hash*. In which case an toolchain file can look like this:

```ruby
  Announce   :mailto   => "ruby-talk@ruby-lang.org",
             :active   => true

  Announce   :myself,
             :mailto   => "transfire@gmail.com",
             :priority => -1
             :active   => true

  Gem        :spec     => false,
             :active   => true

  DNote      :priority => -1,
             :active   => true

  RI         :exclude  => [],
             :active   => true

  RDoc       :include  => [ 'lib', '[A-Z]*' ],
             :exclude  => [ 'Gemfile' ]

  Testrb     :active   => true

  Rubyforge  :sitemap  => {
               :site => name
             },
             :active   => false
```

This format is convenient in that it reduced the amount of extraneous syntax
needed to define tool instances. With Ruby 1.9+ it can be even more conisce
using the new Hash syntax.

```ruby
  Announce :myself,
    mailto:   "transfire@gmail.com",
    priority: -1
    active:   true
```


## YAML-based Toolchain Scripts

We have saved the most concise notation for last. The YAML format is
essentially the same as the traditional Ruby format except that the
main key provides the tool instance name and the type is a setting
which defaults to the name. Also, notice the start document indicator
(`---`). This indicator MUST BE USED for the file to be recognized
as YAML, rather than Ruby.

```yaml
  ---

  announce:
    mailto: transfire@gmail.com
    active: true

  myself:
    type:   Announce
    mailto: transfire@gmail.com
    active: true

  gem:
    autospec: false
    active:   true

  dnote:
    priority: -1
    active:   true

  rdoc:
    include: [ "lib", "[A-Z]*" ]
    exclude: [ "Gemfile" ]

  ri:
    exclude: []
    active:  true

  stats:
    priority: -1
    active:   true

  testrb:
    active: true

  rubyforge:
    type: forge
    sitemap:
      site: <% name %>
    active: false
```

As we can see in the last entry, the YAML format also supports ERB and provides
access to project metadata via the ERB's binding.

With the Ruby format it is easy enough to load external library using
standard `require` and `load` methods. Since the YAML format supports ERB
it can be used to achieve the same effect.

```yaml
  ---
  <% require 'some/external/library' %>
```

