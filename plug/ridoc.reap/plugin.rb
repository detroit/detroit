module Reap
module Plugins

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
    # This plugin provides two services for both the +main+ and +site+ pipelines.
    #
    # * +ridoc+ - Create ri docs
    # * +clean+ - Remove ri docs
    #
    class RIDoc < Plugin

      # Default location to store ri documentation files.
      DEFAULT_OUTPUT       = "doc/ri"

      # Locations to check for existance in deciding where to store ri documentation.
      DEFAULT_OUTPUT_MATCH = "{ri,doc/ri}"

      #DEFAULT_INCLUDE  = "lib/**/*"

      pipeline :main, :document
      pipeline :site, :document

      pipeline :main, :clean
      pipeline :site, :clean

      #available do |project|
      #  !project.metadata.loadpath.empty?
      #end

      #
      def initialize_defaults
        @title  = metadata.title
        @files  = metadata.loadpath.map{ |lp| File.join(lp, '**', '*') } # || DEFAULT_INCLUDE
        @output = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      end

      # Title of documents. Defaults to general metadata title field.
      attr_accessor :title

      # Where to save rdoc files (doc/rdoc).
      attr_accessor :output

      # Which files to include.
      attr_accessor :files

      # Alternate term for #files.
      alias_accessor :include, :files

      # Paths to specifically exclude.
      attr_accessor :exclude

      # Generate ri documentation. This utilizes
      # rdoc to produce the appropriate files.
      #
      def document
        output  = self.output
        input   = self.files
        exclude = self.exclude

        cmdopts = {}
        cmdopts['op']      = output
        cmdopts['exclude'] = exclude

        #input = files #.collect do |i|
        #  dir?(i) ? File.join(i,'**','*') : i
        #end

        if outofdate?(output, *input) or force?
          status "Generating #{output}"

          rm_r(output) if exist?(output) and safe?(output)  # remove old ridocs

          #input = input.collect{ |i| glob(i) }.flatten
          vector = [input, cmdopts]
          if verbose?
            sh "rdoc --ri -a #{vector.to_console}"
          else
            silently do
              sh "rdoc --ri -a #{vector.to_console}"
            end
          end
        else
          status "ri docs are current (#{output})"
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
          status "Removed #{output}" #unless dryrun?
        end
      end

    end

end
end

