# RELEASE HISTORY

## 0.4.0 / 2014-01-14

The big change of this release is the swapping of terminology of
`assembly` and `toolchain`. What was once called an "Assembly" is
now called a "Toolchain" and vice-versa. This, when thought through,
makes much more sense. But it has a big effect on every project that
uses Detroit in that a project's `Assembly` file must be renamed 
to `Toolchain`.

This release also modifies the interface change of the previous release
slightly, such that the `assemble` methods do not have to be manually
defined, although it is still recommended. By default the base class
definition will look to see if a method of the same name as a station
is defined in the tool class. Note this differs from using `respond_to?`
which will return `true` if the method was defined in any part of the
class hierarchy. Instead the method must be defined directly in the class.
This helps ensure there are no accidental name clashes between support
code and assembly stations (which was the purpose of the original
`station_` that was deprecated in the last release). 

Changes:

* Rename `assembly` to `toolchain` and vice-versa.
* No longer *requires* custom `assemble` methods for each tool.
* Improved code organization and plenty of bug fixes.


## 0.3.0 / 2012-04-02

This significant release changes the interface for tools to tap
into the assembly line. Where as before specially named methods
in the form of `station_{stop}` were used, now two special methods
are expected `#assemble?` and `#assemble`. The first checks to see
if a particular stop is supported and the later is used to execute
it if it does.

Changes:

* Simplify the assembly interface for tools.
* Tool classes ending in Base are abstract base class.
* Add #on as alias for #track.


## 0.2.0 / 2011-10-19

The big news here is that Detroit configuration files are now
called _assembly_ files, and no longer _schedule_ files. The
new term is much more fitting the general design and overall
nomenclature of the system. In addition a few general improvements
and bug fixes have been applied. In effect, this is probabaly the
first really usable public release of Detroit.

Changes:

* Schedule was renamed to Assembly.
* Add help system using man-pages.
* Put install phase before verify.
* Add custom method for Ruby-style assemblies.
* Rename ServiceWrapper to Service.
* Firm up standard IO API for tools.
* Fix --config output.


## 0.1.0 / 2011-06-29

Detroit is a lifecycle build system for Ruby. Detroit was originally
called Syckle, and was developed and used in house for Rubyworks projects
for several years. With the renaming of the project, the system has
been simplified, the code cleaned up and the version count reset, in
preperation of it's wider public release.

Changes:

* Happy Release Day!

