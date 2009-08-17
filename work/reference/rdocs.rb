# USE THIS TO CREATE ri TASK>

#!/usr/bin/env ruby

# TODO Should rdoc options be an array or hash instead of a string?

class Project

  # Default files to include in Rdocs.
  DEFAULT_RDOC_FILES = [
    'bin/**/*',
    'lib/**/*',
    'ext/**/*',
    '[A-Z]*',
    '-demo/**/*',
    '-example/**/*',
    '-sample/**/*'
  ]

  # Default rdoc main page.
  DEFAULT_RDOC_MAIN = 'README'

  # Default rdoc template.
  DEFAULT_RDOC_TEMPLATE = 'jamis' #'html'

  # Default rdoc output dir.
  DEFAULT_RDOC_OUTPUT = 'doc/rdoc'

  # Default ri doc output dir.
  DEFAULT_RIDOC_OUTPUT = 'doc/ri'

  # Default rdoc extra options.
  DEFAULT_RDOC_OPTIONS = "--merge --all --inline-source"

  # Default scripts to include in ri docs.
  DEFAULT_RIDOC_FILES = [ 'lib/**/*' ]

  # Generate local ri docs for testing purposes.
  # These will be stored in ri/ either in the 
  # project's main directory or in the same parent
  # directory as the rdocs.
  #
  # User-friendly tasks for generating rdocs and ri docs.
  # The tool presently routes via the rdoc console command.

  def ridoc
    title   = info.title
    scripts = info.scripts
    output  = info.rdoc_output

    output  = File.join(File.dirname(output),'ri') if output

    scripts ||= DEFAULT_RIDOC_FILES
    output  ||= DEFAULT_RIDOC_OUTPUT

    files = Dir.multiglob(scripts) - Dir.multiglob_r(ignore)
    if files.empty?
      puts "No scripts to document."
      return
    end
    files = '"' << files.join('" "') << '"'

    sh %{ rdoc --ri -o #{output} #{files} }
  end

  # Generate API documentation via rdoc.
  #
  #     title      Project title to use in documentation [title].
  #     main       File to use as main page ["README"].
  #     template   Which RDoc template to use ["html"].
  #     files      Files to include and/or exclude in RDocs. You can
  #                  use '+' and '-' prefixes on the file patterns.
  #                  The standard default is in DEFAULT_FILES.
  #     output     Directory to store documentation ["rdoc"].
  #
  #  Additional options will be passed-thru to the RDoc command.
  #--
  #     location   Project's source location to document [location].
  #++

  def rdoc
    title     = info.title
    files     = info.rdoc_files
    main      = info.rdoc_main
    template  = info.rdoc_template
    output    = info.rdoc_output
    options   = info.rdoc_options

    files     ||= DEFAULT_RDOC_FILES
    main      ||= DEFAULT_RDOC_MAIN
    template  ||= DEFAULT_RDOC_TEMPLATE
    output    ||= DEFAULT_RDOC_OUTPUT
    options   ||= DEFAULT_RDOC_OPTIONS

    dir = File.expand_path(output)
    if FileTest.directory?(dir)
      q = "Directory '#{output}' already exists. Clobber?"
      i = ask( q, 'yN' )
      case i.downcase
      when 'y', 'yes', 'okay'
        puts "Removing old directory '#{dir}'..."
        rm_r(dir)
      else
        #abort "Directory '#{@output}' already exists. Use RAKE=force to overwrite."
        puts "Task canceled."
        exit!
      end
    end

    # warn if main file doesnt exist
    if !File.exists?(main) or File.directory?(main)
      #warn "WARNING! Specified RDoc MAIN file #{main} not found."
      main = nil
    end

    # collect files to document
    todoc = []
    todoc << main if main
    todoc += Dir.multiglob_with_default(DEFAULT_RDOC_FILES, files)
    todoc -= Dir.multiglob_r(ignore)
    todoc = '"' << todoc.join('" "') << '"'

    # build options string
    build = []
    build += [options]
    build << "--main '#{main}'" if main
    build << "--title '#{title}'" if title
    build << "-T '#{template}'" if template
    opts = build.join(' ')

    # SHELL OUT! Can RDoc be called from code?
    sh %{rdoc -o #{dir} #{opts} #{todoc}}
  end

#   # Define RDoc tasks.
# 
#   def task_rdoc( options={} )
# 
#     desc "Generate local rdocs"
#     task :rdocs do |task|
#       project.rdoc
#     end
# 
#     desc "Generate local ri docs"
#     task :ridocs do
#       project.ridoc
#     end
# 
#     project.ignore << 'doc/rdoc'
#     project.ignore << 'doc/ri'
#   end


end






=begin
    # Files to document or not (handles '+' and '-' prefixes).
    attr_accessor :files

    # Files to ri document. Default is ['lib/**/*.rb'].
    attr_accessor :scripts

    # Title of project to use in rdocs
    attr_accessor :title

    # File to use as main page [README]
    attr_accessor :main

    # Directory to store documentation [doc/rdoc]
    attr_accessor :output

    # Directory to store ri documentation [doc/ri]
    attr_accessor :ri_output

    # Which RDoc template to use [html]
    attr_accessor :template

    # Pass-thru extra options to RDoc command
    attr_accessor :options

    # Project's source location to document ["."]
    #attr_accessor :location

    #
    def initialize  # :yield: self
      yield self if block_given?

      @files     ||= DEFAULT_RDOC_FILES
      @scripts   ||= DEFAULT_SCRIPT_FILES
      @main      ||= DEFAULT_MAIN
      @template  ||= DEFAULT_TEMPLATE
      @output    ||= DEFAULT_OUTPUT
      @ri_output ||= File.join(File.dirname(@output),'ri')
      @options   ||= DEFAULT_OPTIONS

      IGNORE << @output
      IGNORE << @ri_output

      define
    end
=end
