module Syckle::Plugins

  # RDoc documentation plugin generates RDocs for your project.
  #
  # By default it generates the rdoc documentaiton at doc/rdoc,
  # unless an 'rdoc' directory exists in the project's root
  # directory, in which case the rdoc documentation will be
  # stored there.
  #
  # This plugin provides the following cycle-phases:
  #
  #   main:document  - generate rdocs
  #   main:reset     - mark rdocs out-of-date
  #   main:clean     - remove rdocs
  #
  #   site:document  - generate rdocs
  #   site:reset     - mark rdocs out-of-date
  #   site:clean     - remove rdocs
  #
  # RDoc service will be available automatically if the project
  # has a +doc/rdoc+ directory.
  #
  class RDoc < Service #Plugin

    ##
    # Generate rdocs in main cycle.
    # :method: main_document
    cycle :main, :document

    cycle :main, :reset

    cycle :main, :clean

    cycle :site, :document
    cycle :site, :reset
    cycle :site, :clean

    # TODO: IMPROVE
    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    ## RDoc can run automatically if the project has
    ## a +doc/rdoc+ directory.
    #autorun do |project|
    #  project.root.glob('doc/rdoc').first
    #end

    # Default location to store rdoc documentation files.
    DEFAULT_OUTPUT       = "doc/rdoc"

    # Locations to check for existance in deciding where to store rdoc documentation.
    DEFAULT_OUTPUT_MATCH = "{doc/rdoc,rdoc}"

    # Default main file.
    DEFAULT_MAIN         = "README{,.*}"

    # Default rdoc template to use.
    DEFAULT_TEMPLATE     = "darkfish"

    # Deafult extra options to add to rdoc call.
    DEFAULT_EXTRA        = ''

  private

    # Setup default attribute values.
    def initialize_defaults
      @title    = metadata.title
      @files    = metadata.loadpath + ['[A-Z]*', 'bin'] # DEFAULT_FILES
      @output   = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @extra    = DEFAULT_EXTRA
      @main     = Dir[DEFAULT_MAIN].first
      @template = ENV['RDOC_TEMPLATE'] || DEFAULT_TEMPLATE
    end

  public

    # Title of documents. Defaults to general metadata title field.
    attr_accessor :title

    # Where to save rdoc files (doc/rdoc).
    attr_accessor :output

    # Template to use (defaults to ENV['RDOC_TEMPLATE'] or 'darkfish')
    attr_accessor :template

    # Main file.  This can be a file pattern. (README{,.*})
    attr_accessor :main

    # Which files to document.
    attr_accessor :files

    # Alias for +files+.
    alias_accessor :include, :files

    # Paths to specifically exclude.
    attr_accessor :exclude

    # File patterns to ignore.
    #attr_accessor :ignore

    # Ad file html snippet to add to html rdocs.
    attr_accessor :adfile

    # Additional options passed to the rdoc command.
    attr_accessor :extra

    # Generate Rdoc documentation. Settings are the
    # same as the rdoc command's option, with two
    # exceptions: +inline+ for +inline-source+ and
    # +output+ for +op+.
    #
    def document(options=nil)
      options ||= {}

      title    = options['title']    || self.title
      output   = options['output']   || self.output
      main     = options['main']     || self.main
      template = options['template'] || self.template
      files    = options['files']    || self.files
      exclude  = options['exclude']  || self.exclude
      adfile   = options['adfile']   || self.adfile
      extra    = options['extra']    || self.extra

      # NOTE: Due to a bug in RDoc this needs to be done for now
      # so that alternate templates can be used.
      begin
        require 'rubygems'
        gem('rdoc')
      rescue LoadError
      end

      require 'rdoc/rdoc'

      # you can specify more than one possibility, first match wins
      adfile = [adfile].flatten.compact.find do |f|
        File.exist?(f)
      end

      main = Dir.glob(main, File::FNM_CASEFOLD).first

      include_files = files.to_list.uniq
      exclude_files = exclude.to_list.uniq

      if mfile = project.manifest_file
        exclude_files << mfile.basename.to_s # TODO: I think base name should retun a string?
      end

      filelist = amass(include_files, exclude_files)
      filelist = filelist.select{ |fname| File.file?(fname) }

      if outofdate?(output, *filelist) or force?
        status "Generating #{output}"

        #target_main = Dir.glob(target['main'].to_s, File::FNM_CASEFOLD).first
        #target_main   = File.expand_path(target_main) if target_main
        #target_output = File.expand_path(File.join(output, subdir))
        #target_output = File.join(output, subdir)

        argv = []
        argv.concat(extra.split(/\s+/))
        argv.concat ['--op', output]
        argv.concat ['--main', main] if main
        argv.concat ['--template', template] if template
        argv.concat ['--title', title] if title

        #exclude_files.each do |file|
        #  argv.concat ['--exclude', file]
        #end

        argv = argv + filelist #include_files

        rdoc_target(output, include_files, argv)
        rdoc_insert_ads(output, adfile)

        touch(output)
      else
        status "RDocs are current (#{output})."
      end
    end

    # Reset output directory, marking it as out-of-date.
    def reset
      if File.directory?(output)
        File.utime(0,0,output)
        report "reset #{output}" #unless trial?
      end
    end

    # Remove rdocs products.
    def clean
      if File.directory?(output)
        rm_r(output)
        report "removed #{output}" #unless trial?
      end
    end

  private

    # Generate rdocs for input targets.
    #
    # TODO: Use RDoc programmatically rather than via shell.
    #
    def rdoc_target(output, input, argv=[])
      #if outofdate?(output, *input) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old rdocs

        #rdocopt['op'] = output

        #if template == 'hanna'
        #  cmd = "hanna #{extra} " + [input, rdocopt].to_console
        #else
        #  cmd = "rdoc #{extra} " + [input, rdocopt].to_console
        #end

        #argv = ("#{extra}" + [input, rdocopt].to_console).split(/\s+/)

        if verbose? or trial?
          puts "rdoc " + argv.join(" ")
          #sh(cmd) #shell(cmd)
        else
          puts "rdoc " + argv.join(" ") if trace?
          rdoc = ::RDoc::RDoc.new
          rdoc.document(argv)
          #silently do
          #  sh(cmd) #shell(cmd)
          #end
        end
      #else
      #  puts "RDocs are current -- #{output}"
      #end
    end

    # Insert an ad into rdocs, if exists.
    #
    # Note that this code is needs work, as is it
    # was designed to work with an old version of RDoc.
    #
    def rdoc_insert_ads(site, adfile)
      return if trial?
      return unless adfile && File.file?(adfile)
      adtext = File.read(adfile)
      #puts
      dirs = Dir.glob(File.join(site,'*/'))
      dirs.each do |dir|
        files = Dir.glob(File.join(dir, '**/*.html'))
        files.each do |file|
          html = File.read(file)
          bodi = html.index('<body>')
          next unless bodi
          html[bodi + 7] = "\n" + adtext
          File.write(file, html) unless trial?
        end
      end
    end

  end

end

