module Redline::Plugins

  # = RI Documentation Plugin
  #
  # The ri documentation plugin provides services for
  # generating ri documentation.
  #
  # By default it generates the ri documentaiton at doc/ri,
  # unless an 'ri' directory exists in the project's root
  # directory, in which case the ri documentation will be
  # stored there.
  #
  # This plugin provides the following cycle-phases:
  #
  #   main:document  - generate ri docs
  #   main:reset     - mark ri docs out-of-date
  #   main:clean     - remove ri docs
  #
  #   site:document  - generate ri docs
  #   site:reset     - mark ri docs out-of-date
  #   site:clean     - remove ri docs
  #
  class RI < Service

    stop :main, :document
    stop :main, :reset
    stop :main, :clean

    stop :site, :document
    stop :site, :reset
    stop :site, :clean

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    ## RIDoc can run automatically if the project has
    ## a +doc/ri+ directory.
    #autorun do |project|
    #  project.root.glob('doc/ri').first
    #end

    # Default location to store ri documentation files.
    DEFAULT_OUTPUT       = "doc/ri"

    # Locations to check for existance in deciding where to store ri documentation.
    DEFAULT_OUTPUT_MATCH = "{doc/ri,ri}"

    # Deafult extra options to add to rdoc call.
    DEFAULT_EXTRA        = ''

    #
    def initialize_defaults
      @files  = metadata.loadpath
      @output = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @extra  = DEFAULT_EXTRA
    end

    # Where to save rdoc files (doc/rdoc).
    attr_accessor :output

    # Which files to include.
    attr_accessor :files

    # Alternate term for #files.
    alias_accessor :include, :files

    # Paths to specifically exclude.
    attr_accessor :exclude

    # Additional options passed to the rdoc command.
    attr_accessor :extra

    # Generate ri documentation. This utilizes
    # rdoc to produce the appropriate files.
    #
    def document
      output  = self.output
      input   = self.files
      exclude = self.exclude

      include_files = files.to_list.uniq
      exclude_files = exclude.to_list.uniq

      filelist = amass(include_files, exclude_files)

      if outofdate?(output, *filelist) or force?
        status "Generating #{output}"

        cmdopts = {}
        cmdopts['op']      = output
        cmdopts['exclude'] = exclude

        ridoc_target(output, include_files, cmdopts)

        touch(output)
      else
        status "RI docs are current (#{output})"
      end
    end

    # Set the output directory's mtime to furthest time in past.
    # This "marks" the documentation as out-of-date.
    def reset
      if File.directory?(output)
        File.utime(0,0,self.output)
        report "reset #{output}"
      end
    end

    # Remove ri products.
    def clean
      if File.directory?(output)
        rm_r(output)
        status "Removed #{output}" #unless trial?
      end
    end

  private

    # Generate ri docs for input targets.
    #
    # TODO: Use RDoc programmatically rather than via shell.
    #
    def ridoc_target(output, input, rdocopt={})
      rm_r(output) if exist?(output) and safe?(output)  # remove old ri docs

      rdocopt['op'] = output

      cmd = "rdoc --ri -a #{extra} " + [input, rdocopt].to_console

      if verbose? or trial?
        sh(cmd)
      else
        silently do
          sh(cmd)
        end
      end
    end

  end

end
