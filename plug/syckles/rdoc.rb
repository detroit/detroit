module Syckles

  # RDoc documentation plugin generates RDocs for your project.
  #
  # By default it generates the rdoc documentaiton at doc/rdoc,
  # unless an 'rdoc' directory exists in the project's root
  # directory, in which case the rdoc documentation will be
  # stored there.
  #
  # This plugin provides two services for both the +main+ and +site+ pipelines.
  #
  # * +document+ - create rdocs
  # * +clean+    - remove rdocs
  #
  class RDoc < Service

    cycle :main, :document
    cycle :site, :document

    cycle :main, :clean
    cycle :site, :clean

    # TODO: IMPROVE
    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Default location to store rdoc documentation files.
    DEFAULT_OUTPUT       = "doc/rdoc"

    # Locations to check for existance in deciding where to store rdoc documentation.
    DEFAULT_OUTPUT_MATCH = "{rdoc,doc/rdoc}"

    # Default main file.
    DEFAULT_MAIN         = "README"

    # Default rdoc template to use.
    DEFAULT_TEMPLATE     = "darkfish"

    # Deafult extra options to add to rdoc call.
    DEFAULT_EXTRA        = ''

    #DEFAULT_FILES        = '[A-Z]*;lib/**/*;bin/*'

  private

    # Setup default attribute values.
    def initialize_defaults
      @title    = metadata.title
      @files    = metadata.loadpath + ['[A-Z]*', 'bin'] # DEFAULT_FILES

      @output   = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @main     = DEFAULT_MAIN
      @extra    = DEFAULT_EXTRA
      @template = ENV['RDOC_TEMPLATE'] || DEFAULT_TEMPLATE
    end

    #def main_document ; document ; end
    #def site_document ; document ; end
    #def main_clean    ; clean    ; end
    #def site_clean    ; clean    ; end

  public

    # Title of documents. Defaults to general metadata title field.
    attr_accessor :title

    # Where to save rdoc files (doc/rdoc).
    attr_accessor :output

    # Template to use (defaults to ENV['RDOC_TEMPLATE'] or 'html')
    attr_accessor :template

    # Main file.  This can be file pattern. (README{,.txt})
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

      if outofdate?(output, *filelist) or force?
        status "Generating #{output}"

        #target_main = Dir.glob(target['main'].to_s, File::FNM_CASEFOLD).first
        #target_main   = File.expand_path(target_main) if target_main
        #target_output = File.expand_path(File.join(output, subdir))
        #target_output = File.join(output, subdir)

        cmdopts = {}
        cmdopts['op']         = output
        cmdopts['main']       = main if main
        cmdopts['template']   = template
        cmdopts['title']      = title
        cmdopts['exclude']    = exclude_files

        rdoc_target(output, include_files, cmdopts)
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
        report "reset #{output}" #unless dryrun?
      end
    end

    # Remove rdocs products.
    def clean
      if File.directory?(output)
        rm_r(output)
        status "removed #{output}" #unless dryrun?
      end
    end

  private

    # Generate rdocs for input targets.
    #
    # TODO: Use RDoc programmatically rather than via shell.
    #
    def rdoc_target(output, input, rdocopt={})
      #if outofdate?(output, *input) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old rdocs

        rdocopt['op'] = output

        if template == 'hanna'
          cmd = "hanna #{extra} " + [input, rdocopt].to_console
        else
          cmd = "rdoc #{extra} " + [input, rdocopt].to_console
        end

        if verbose? or dryrun?
          shell(cmd)
        else
          silently do
            shell(cmd)
          end
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
      return if dryrun?
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
          File.write(file, html) unless dryrun?
        end
      end
    end

  end

end
