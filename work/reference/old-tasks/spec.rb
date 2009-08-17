module Reap

  class Project

#    DEFAULT['spec'] = {
#      'specs'   => ['spec/**/*_spec.rb', 'spec/**/spec_*.rb'],
#      'require' => [],
#      'warning' => false,
#      'command' => ['spec']
#    }

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

    def spec(options=nil)
      options = configure_options(options, 'spec')

      #specs   = options['specs']    || DEFAULT['spec']['specs']
      #reqs    = options['require']  || DEFAULT['spec']['require']
      #warning = options['warning']  || DEFAULT['spec']['false']
      #command = options['command']  || DEFAULT['spec']['command']

      specs    = options['specs']
      warning  = options['warning']
      command  = options['command']  || 'spec'
      loadpath = options['loadpath'] || metadata.loadpath
      format   = options['format']
      rubyopt  = options['rubyopt']
      specopt  = options['specopt']
      live     = options['live']

      specs    = list_option(specs)
      loadpath = list_option(loadpath)
      requires = list_option(requires)

      files = multiglob(*specs)

      if files.empty?
        puts "No specifications."
      else
        #RakeFileUtils.verbose(verbose) do
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
        #end
      end
    end

    # Run all specs with text output

    def spec_doc(options=nil)
      options ||= {}
      options['format'] = 'specdoc'
      spec(options)
    end

  end

end

