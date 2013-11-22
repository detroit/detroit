= RELEASE HISTORY

== 0.3.0 / 2012-04-02

This significant release changes the interface for tools to tap
into the assembly line. Where as before specially named methods
in the form of `station_{stop}` were used, now two special methods
are expected `#assemble?` and `#assemble`. The first checks to see
if a particular stop is supported and the later is used to execute
it if it does.

Changes:

* Simplify the assembly interface for tools.
* Tool classes ending in Base are abstract base class.
* Add #on as alias from #track.


== 0.2.0 / 2011-10-19

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


== 0.1.0 / 2011-06-29

Detroit is a lifecycle build system for Ruby. Detroit was originally
called Syckle, and was developed and used in house for Rubyworks projects
for several years. With the renaming of the project, the system has
been simplified, the code cleaned up and the version count reset, in
preperation of it's wider public release.

Changes:

* Happy Release Day!

