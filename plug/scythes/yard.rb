module Syckles

  # Yard documentation plugin generates docs for your project.
  #
  # By default it generates the yard documentaiton at doc/yard,
  # unless an 'yard' directory exists in the project's root
  # directory, in which case the documentation will be stored there.
  #
  # This plugin provides two services for both the +main+ and +site+ pipelines.
  #
  # * +document+ - create yard docs
  # * +clean+    - remove yard docs
  #
  class Yard < Service

    cycle :main, :document
    cycle :site, :document

    cycle :main, :clean
    cycle :site, :clean

    # TODO: IMPROVE
    available do |project|
      !project.metadata.loadpath.empty?
    end

    # Default location to store yard documentation files.
    DEFAULT_OUTPUT       = "doc/yard"

    # Locations to check for existance in deciding where to store yard documentation.
    DEFAULT_OUTPUT_MATCH = "{yard,doc/yard}"

    # Default main file.
    DEFAULT_README       = "README"

    # Default template to use.
    DEFAULT_TEMPLATE     = "default"

    # Deafult extra options to add to yardoc call.
    DEFAULT_EXTRA        = ''

    #DEFAULT_FILES        = '[A-Z]*;lib/**/*;bin/*'

    #
    def initialize_defaults
      @title    = metadata.title
      @files    = metadata.loadpath + ['[A-Z]*', 'bin'] # DEFAULT_FILES

      @output   = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @readme   = DEFAULT_README
      @extra    = DEFAULT_EXTRA
      @template = ENV['YARD_TEMPLATE'] || DEFAULT_TEMPLATE
    end

    #def main_document ; document ; end
    #def site_document ; document ; end
    #def main_clean    ; clean    ; end
    #def site_clean    ; clean    ; end

  public

    # Title of documents. Defaults to general metadata title field.
    attr_accessor :title

    # Where to save yard files (doc/yard).
    attr_accessor :output

    # Template to use (defaults to ENV['RDOC_TEMPLATE'] or 'html')
    attr_accessor :template

    # Main file.  This can be file pattern. (README{,.txt})
    attr_accessor :readme

    # Which files to document.
    attr_accessor :files

    # Alias for +files+.
    alias_accessor :include, :files

    # Paths to specifically exclude.
    attr_accessor :exclude

    # Ad file html snippet to add to html.
    attr_accessor :adfile

    # Additional options passed to the yardoc command.
    attr_accessor :extra

    # Generate Rdoc documentation. Settings are the
    # same as the yardoc command's option, with two
    # exceptions: +inline+ for +inline-source+ and
    # +output+ for +op+.
    #
    def document(options=nil)
      options ||= {}

      title    = options['title']    || self.title
      output   = options['output']   || self.output
      readme   = options['readme']   || self.readme
      template = options['template'] || self.template
      files    = options['files']    || self.files
      exclude  = options['exclude']  || self.exclude
      extra    = options['extra']    || self.extra
      adfile   = options['adfile']   || self.adfile

      # you can specify more than one possibility, first match wins
      adfile = [adfile].flatten.compact.find do |f|
        File.exist?(f)
      end

      readme = Dir.glob(readme, File::FNM_CASEFOLD).first

      # YARD SUCKS --THIS DOESN'T WORK ON YARD LINE, WE MUST DO IT OURSELVES!!!
      exclude = exclude.to_list
      exclude = exclude.collect{ |g| Dir.glob(File.join(g, '**/*')) }.flatten

      files = files.to_list
      files = files.map{ |g| Dir.glob(g) }.flatten
      files = files.map{ |f| File.directory?(f) ? File.join(f,'**','*') : f }
      files = files.map{ |g| Dir.glob(g) }.flatten  # need this to remove unwanted toplevel files
      files = files.reject{ |f| File.directory?(f) }

      files = files - Dir.glob('rakefile{,.rb}', File::FNM_CASEFOLD)

      mfile = project.manifest_file
      mfile = project.manifest_file.basename if mfile

      exclude = (exclude + [mfile].compact).uniq

      files = files - [mfile].compact
      files = files - exclude

      input = files.uniq

      if outofdate?(output, *input) or force?
        status "Generating #{output}"

        #target_main = Dir.glob(target['main'].to_s, File::FNM_CASEFOLD).first
        #target_main   = File.expand_path(target_main) if target_main
        #target_output = File.expand_path(File.join(output, subdir))
        #target_output = File.join(output, subdir)

        cmdopts = {}
        cmdopts['output-dir'] = output
        cmdopts['readme']     = readme if readme
        cmdopts['template']   = template
        cmdopts['title']      = title
        #cmdopts['exclude']   = exclude

        yard_target(output, input, cmdopts)
        #rdoc_insert_ads(output, adfile)

        touch(output)
      else
        status "Yardocs are current (#{output})."
      end
    end

    # Remove yardoc products.

    def clean(options=nil)
      output = options['output'] || self.output #|| 'doc/yard'

      if File.directory?(output)
        rm_r(output)
        status "Removed #{output}" unless dryrun?
      end
    end

  private

    # Generate yardocs for input targets.
    #
    # TODO: Use Yard programmatically rather than via shell.
    #
    def yard_target(output, input, options={})
      #if outofdate?(output, *input) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old rdocs

        options['output-dir'] = output

        cmd = "yardoc #{extra} " + [input, options].to_console

        if verbose? or dryrun?
          shell(cmd)
        else
          silently do
            shell(cmd)
          end
        end
      #else
      #  puts "Yardocs are current -- #{output}"
      #end
    end

    # Insert an ad into rdocs, if available.
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
