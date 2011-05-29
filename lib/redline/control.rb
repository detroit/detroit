module Redline

  # The control module is a function module that extends the topleve Redline
  # namespace module.
  #
  module Control

    # Location of standard plugins.
    PLUGIN_DIRECTORY = File.dirname(__FILE__) + '/plugins'

    # Returns Array of standard plugin file names.
    def standard_plugins
      Dir[PLUGIN_DIRECTORY + '/*.rb']
    end

    # Universal acccess to the current project.
    def project
      @project ||= POM::Project.find
    end

    #
    def application(cli_options)
      Application.new(cli_options)
    end

    #
    def cli(*argv)
      cli_options = {
        :trace=>nil, :trial=>nil, :debug=>nil, :quiet=>nil, :verbose=>nil,
        :force=>nil, :multitask=>nil, :skip=>[]
      }

      cli_usage(cli_options).parse!(argv)

      if /\.redfile$/ =~ argv[0]
        job = argv[1]
        application(cli_options).runscript(argv[0], job)
      else
        application(cli_options).start(*argv)
      end
    end

    #
    def cli_usage(options)
      @usage ||= (
        OptionParser.new do |usage|
          usage.banner = "Usage: redline [<track>:]<stop> [options]"
          usage.on('--trace', "Run in TRACE mode.") do
            #$TRACE = true
            options[:trace] = true
          end
          usage.on('--trial', "Run in TRIAL mode (no disk writes).") do
            #$TRIAL = true
            options[:trial] =true
          end
          # TODO: do we really need verbose?
          usage.on('--verbose', "Provided extra output.") do
            options[:verbose] = true
          end
          usage.on('-q', '--quiet', "Run silently.") do
            options[:quiet] = true
          end
          usage.on('--force', "Force operations.") do
            options[:force] = true
          end
          usage.on('-m', '--multitask', "Run in parallel.") do
            options[:multitask] = true
          end
          usage.on('-s', '--skip [SERVICE]', 'Skip service.') do |s|
            options[:skip] << s
          end
          usage.on('--debug', "Run with $DEBUG set to true.") do
            $DEBUG   = true
            options[:debug] = true  # DEPRECATE
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
