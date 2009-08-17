

      <div class="ad">
        <script type="text/javascript"><!--
        google_ad_client = "pub-1126154564663472";
        //RATCH 728x90, 11/8/07
        google_ad_slot = "6500283279";
        google_ad_width = 728;
        google_ad_height = 90;
        //--></script>
        <script type="text/javascript"
        src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
        </script>
      </div>














h1. UNDER CONSTRUCTION

h1. Interoperability

h2. Ratch a la Rake

Rake is the the popular choice for Ruby delvelopers. Since Ratch is alsow written Ruby it is possible
to use Ratch tasks via one;s Rakefile. This can be approached in either of two ways.

Since Ratch' project tools are designed as stand-alone reusable modules, one can
access them directly. For instance let's define an RDoc task by calling directly on
Ratcehts' <code>Doc.rdoc</code> module method.

    <pre class="script">
      require 'ratchets/doc'

      desc 'rdoc the project'

      task :rdoc do
        Ratchets::Doc.rdoc do |r|
          r.title    = "MyApplication"
          r.main     = "README"
          r.template = "html"
          r.options  = ["--all", "--inline-source"]
          r.include  = ["lib/**/*", "bin/*", "[A-Z]*"]
          r.basedir  = "src"
          r.output   = "rdoc"
        end
      end
    </pre>

This usage leaves everything up to the the Rake file. Although most of these fields have reasonable
defaults. Nonetheless, no information is being provided to the tool via a project information file,
becuase we are invoking Ratchet's underlying rdoc tool directly.

Now let's do the same thing, but via the Project class.

    <pre>
      require 'ratchets/project'

      project = Project.new do |info|
        info.title   = "MyApplication"
        info.basedir = "src"
      end


      desc 'rdoc the project'

      task :rdoc do
        project.rdoc do |r|
          r.main     = "README"
          r.template = "html"
          r.options  = ["--all", "--inline-source"]
          r.include  = ["lib/**/*", "bin/*", "[A-Z]*"]
          r.output   = "rdoc"
        end
      end
    </pre>

Here we have created a new Project object and have invoked the rdoc tool <i>via</i> it's interface.
This automatically incorporates general information about the project of use to the tool --in this case
the project's title and it's basedir. The other fields are rdoc specific so they cannot be shared.
But we can go a step further and define a set of <i>tool specific defaults</i> for any rdoc task.

    <pre>
      require 'ratchets/project'

      project = Project.new(
        :title   => "MyApplication"
        :basedir => "src"
        :rdoc    => {
          :main     => 'README'
          :template => "html"
          :options  => ["--all", "--inline-source"]
          :include  => ["lib/**/*", "bin/*", "[A-Z]*"]
          :output   => "rdoc"
        }
      )

      desc 'rdoc the project'

      task :rdoc do
        project.rdoc
      end
    </pre>

You'll also notice that we are demonstrating Ratchet's versitility in accepting arguments.
The <code>Project.new</code> method can take either a hash <u>or</u> a block. In fact, this is
a widely used pattern throughout Ratchets.

One final step. It's is likely we don't need to fuss with each and every tool Ratchets
provides us. All-in-all we will probably want most, if not all, of them avaialble to us, and
since Ratcehts generally provides reasonable defaults for most fields, we will rarely have
to explicitly fill out each one. In fact, every field we gave thus far for rdoc, except
title and basedir, are the default settings. So to facilitate this, the project class has an
<code>autonew</code> method which automatically generates all the tasks for every project tool
Ratchets offers.

    <pre>
      require 'ratchets/project'

      project = Project.autonew(
        :title   => "MyApplication"
        :basedir => "src"
      )
    </pre>

Now when you invoke <code>Rake -T</code> you will see a good sized list of available tasks.

The techinque as discussed thus far is quite usable, and those heavily favoring pure Rake usage
may wish to venture no further than right here. But there are is one final variation that has
it's own benefits. Rather then store the project information as Ruby code within one's Rakefile,
the information can be placed in a separate <i>ProjectInfo</i> file (something you are already
familiar with if you read about Project Generation). To utilize this file, instead of using the
<code>new</code> or <code>autonew</code> methods you instead use the <code>load</code> and
<code>autoload</code> methods. The upshot is that your typical Rakefile may have little more
than these two-lines:

    <pre>
      require 'ratchets/project'
      Project.autoload
    </pre>







<!--Adding code to a rakefile or a sake-style script is fine for one-off tasks. But what if you
need a more versitle and reusable tool --one you can add to your projectinfo file like Ratchets
built-in tools? In that case you need to build a <i>custom tool</i>.

If you have custom tools you'd like to use for all your projects you can place them
either in you home directory under ~/.share/ratchets/tools/, or you could make them
universally available to all users in the shared data directory, on Debian,
/usr/share/ratchets/tools/. If, on the other hand, the tool is specific to a project,
place it in a project tools/ folder.-->





<!--h2. Task Versitility

Ratchets is a very versitile application. Ratchets supports a number of techniques
for utilizing it's built-in tools and defining new tasks. Depedending on the desired usage,
Ratchets can be a build tool <i>library</i>, or taking advantage of it's own system, can
be used as a build tool in its own right.

One easily adopted usage of Ratchets is as a build library invoked from Rake.
Rake is the prevalent build tool for Ruby, and an excellent one at that. Ratchets
tools can be easily called from any application, so calling them from a Rake task
is a natural endeavor. Ratchets goes a step further in its support of Rake however
by allowing the built-in tools to be setup as Rake tasks automatically.
If this is intended usage jump down to <a href="#ch4">Ratchets a la Rake</a>
to learn more.

On the other hand, forgoing a separate build tool, tasks can instead be defined
as YAML descriptors and invoked via thae <code>project</code> command-line utility.
This makes tasks extremely easy to read and write, and allows project information
and task definitions to be jointly located but still universally accessible as
pure data. We will cover this usage in <a href="#ch2">Describing Tasks
via YAML</a>.

The other alternative, which we will discuss last, is for tasks to be defined as
stand-alone executables. This approach is in the spirit of Unix --it's favor of many
small tools over single monolithic applications. Ratchets provides strong support
for this mode of operation, which we have dubbed the <a href="#ch3">Sake Technique</a>.
[ed- In fact, it is my prefered usage.]

In any case, no matter which technique is used. The centralized data resource
for project information is readily available. This <i>reapability</i> of
information, probably more than any other feature, makes Ratchets so effective.-->

 <!--

  <p>The conversion is almost seemless. The task class needs only conform to some simple conventions (in this case
  for example you can see the package_file.include needs to be reduced to a single 'include' attribnute) which are farily
  trivial to implement. This format has been a big hit with Reap's users. Of course it's optional, one can still do
  everything through the Reapfile (but why?).</p>


  <h2>Sake may have some nice built-in tasks, but we use Rake. So what good is it?</h2>

  <p>Sake's unix style of many small scripts is fairly orthongonal to Rake's,
  So you can still call upon Sake's built-in scripts in your Rakefile, if you so prefer.
  Check it out:</p>

    <pre>
      require 'sake/project'

      desc "Generate RDocs"

      task :rdoc do
        Automation.rdoc do |s|
          s.template = 'jamis'
          s.include = 'lib/**/*'
        end
      end
    </pre>

  <p>Of course, you don't have to use Reap's task system. You can still use Rake's for all your project tasks if
  you prefer or for some reason must, and you can still get Reap's task functionality. Reap provides a simple interface
  for doing this. Here's an example of a Rakefile using Reap.</p>

    <pre>
      require 'reap/reap'

      task_package 'pack' do |pkg|
        pkg.distribute = [ 'gem' ]
        pkg.dependencies = [ facets ]
      end
    </pre>

  <p>In the above, all information is provided directly via the Ruby task code. No information is coming from the
  projectinfo file (same is tru for a Reapfile). But you can also use Rake while utilizing the projectinfo file if
  you wish. In your Rakefile simple put:</p>

    <pre>
      require 'reap/rake'
    </pre>

  <p>Then all the tasks defined in the projectinfo file will be available via Rake. You can still add additional
  Rake tasks, of course.</p>

  <p>Reap can be used in the same fashion as Rake. Simply create a Reapfile and use the <code>reap</code>
  command to utilize your tasks.</p>

  <p>Adding a extra Reap task is pretty easy. Just define a task in a the special <i>meta/reapfile</i>.
  If you have ever created a task in Rake's 'Rakefile' then you know how to do it here too. A simple
  task would look like this:</p>

    <pre>
      desc "My special task"
      task :hello do
        puts "Hello, World!"
      end
    </pre>

  <p>You may not like keeping a "monolithic" file of tasks and instead prefer to keep a collection of
  individual task scripts. You can do this by placing your script in the <i>meta/tasks</i> folder and
  encapsulating your task defintion in the Tasks module.</p>

    <pre>
      module Tasks

        desc "My special task"
        task :hello do
          puts "Hello, World!"
        end

      end
    </pre>

  -->
