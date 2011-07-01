module Detroit

  # The control module is a function module that extends
  # the toplevel Detroit namespace module.
  module Control

    # Location of standard plugins.
    #PLUGIN_DIRECTORY = File.dirname(__FILE__) + '/plugins'

    # Returns Array of standard plugin file names.
    #def standard_plugins
    #  Dir[PLUGIN_DIRECTORY + '/*.rb']
    #end

    # Universal acccess to the current project.
    #
    # TODO: Is Control#project being used?
    def project
      @project ||= POM::Project.find
    end

    # Returns Application given options.
    def application(options={})
      Application.new(options)
    end

    # Run the command line interface.
    def cli(*argv)
      cli_options = {
        :system => nil, :assemblies => [], 
        :trace=>nil, :trial=>nil, :debug=>nil, :quiet=>nil, :verbose=>nil,
        :force=>nil, :multitask=>nil, :skip=>[]
      }

      cli_usage(cli_options).parse!(argv)

      #if /\.assembly$/ =~ argv[0]
      #  job = argv[1]
      #  begin
      #    application(cli_options).runscript(argv[0], job)
      #  rescue => error
      #    $stderr.puts error.message
      #    exit -1
      #  end
      #else
        begin
          application(cli_options).start(*argv)
        rescue => error
          if $DEBUG
            raise error
          else
            $stderr.puts error.message
            exit -1
          end
        end
      #end
    end

    # Returns an instance of OptionParser.
    def cli_usage(options)
      @usage ||= (
        OptionParser.new do |usage|
          usage.banner = "Usage: detroit [<track>:]<stop> [options]"
          usage.on('-m', '--multitask', "Run work elements in parallel.") do
            options[:multitask] = true
          end
          usage.on('-S', '--skip [SERVICE]', 'Skip a service.') do |skip|
            options[:skip] << skip
          end

          usage.on('-s', '--system=NAME', "Select assembly system. Default is `standard'.") do |system|
            options[:system] = system
          end

          usage.on('-a', '--assembly [FILE]', 'Use specific assembly file(s).') do |file|
            options[:assemblies] << file
          end

          usage.on('-F', '--force', "Force operations.") do
            options[:force] = true
          end
          usage.on('--trace', "Run in TRACE mode.") do
            #$TRACE = true
            options[:trace] = true
          end
          usage.on('--trial', "Run in TRIAL mode (no disk writes).") do
            #$TRIAL = true
            options[:trial] = true
          end
          # TODO: do we really need verbose?
          usage.on('--verbose', "Provided extra output.") do
            options[:verbose] = true
          end
          usage.on('-q', '--quiet', "Run silently.") do
            options[:quiet] = true
          end

          usage.on('-I=PATH', "Add directory to $LOAD_PATH") do |dirs|
            dirs.to_list.each do |dir|
              $LOAD_PATH.unshift(dir)
            end
          end
          usage.on('--debug', "Run with $DEBUG set to true.") do
            $DEBUG   = true
            options[:debug] = true  # DEPRECATE?
          end
          usage.on('--warn', "Run with $VERBOSE set to true.") do
            $VERBOSE = true  # wish this were called $WARN
          end
          usage.on_tail('--help', "Display this help message.") do
            puts usage
            exit
          end
          usage.on_tail('--config', "Produce a configuration template.") do
            puts application.config_template.to_yaml
            exit
          end
        end
      )
    end

  end

  extend Control
end
