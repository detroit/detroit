module Syckles

  # = RSpec Plugin
  #
  class RSpec < Service

    cycle :main, :validate
    cycle :main, :document

    # Only availabel if there is a spec/ directory.
    # TODO: Is this too restrictive?
    available do |project|
      Dir['spec']
    end

    # File glob(s) of spec files. Defaults to ['spec/**/*_spec.rb', 'spec/**/spec_*.rb'].
    attr_accessor :specs

    # Paths to add $LOAD_PATH. Defaults to ['lib'].
    attr_accessor :loadpath

    # Ignore loadpath, use installed libraries instead. Default is false.
    #attr_accessor :live

    # Lib(s) to require before excuting specifications.
    attr_accessor :require

    # Whether to show warnings or not. Default is false.
    attr_accessor :warning

    # Spec command to use. Defaults to 'spec'.
    attr_accessor :command

    # Format of RSpec output.
    attr_accessor :format

    # Additional options to pass to the ruby command.
    attr_accessor :rubyopt

    # Additional commandline options for spec command.
    attr_accessor :specopt


    def initialize_defaults
      @loadpath = metadata.loadpath

      @specs    = ['spec/**/*_spec.rb', 'spec/**/spec_*.rb']
      @require  = []
      @warning  = false
      @command  = 'spec'
    end

    # Run all specs with basic output.
    #
    # Options:
    #   specs     File glob(s) of spec files. Defaults to ['spec/**/*_spec.rb', 'spec/**/spec_*.rb'].
    #   loadpath  Paths to add $LOAD_PATH. Defaults to ['lib'].
    #   live      Ignore loadpath, use installed libraries instead. Default is false.
    #   require   Lib(s) to require before excuting specifications.
    #   warning   Whether to show warnings or not. Default is false.
    #   command   Spec command to use. Defaults to 'spec'.
    #   format    Format of RSpec output.
    #   rubyopt   Additional options to pass to the ruby command.
    #   specopt   Additional commandline options for spec command.
    #--
    # RCOV suppot?
    #   ruby [ruby_opts] -Ilib -S rcov [rcov_opts] bin/spec -- examples [spec_opts]
    #++

    def validate
      shellout
    end

    # Run all specs with text output

    def document
      shellout('specdoc')
    end

  private

    def shellout(format=nil)
      specs    = self.specs.to_list
      loadpath = self.loadpath.to_list
      requires = self.requires.to_list

      files = multiglob(*specs)

      if files.empty?
        puts "No specifications."
      else
        # ruby [ruby_opts] -Ilib bin/spec examples [spec_opts]
        cmd = "ruby"
        cmd << " -w" if warning
        cmd << %[ -I"#{loadpath.join(':')}"] unless loadpath.empty?
        cmd << %[ -r"#{requires.join(':')}"] unless requires.empty?
        cmd << rubyopt #.join(" ")
        cmd << " "
        #rb_opts << "-S rcov" if rcov
        #cmd << rcov_option_list
        #cmd << %[ -o "#{rcov_dir}" ] if rcov
        cmd << command
        cmd << " "
        #cmd << "-- " if rcov
        cmd << files.join(' ')
        cmd << " "
        cmd << specopt #.join(' ')
        cmd << " --format #{format}" if format

        puts cmd if verbose?
        unless system(cmd)
          STDERR.puts failure_message if failure_message
          raise("Command #{cmd} failed") if fail_on_error
        end
      end
    end

  end#class RSpec

end

