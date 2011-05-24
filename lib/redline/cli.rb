require 'redline/application'
require 'optparse'

module Redline

  # = Commandline Interface
  #
  class CLI

    #
    attr :usage

    #
    attr :options

    #
    def initialize
      initialize_options
      initialize_usage
    end

    #
    def initialize_options
      @options = {
        :trace=>nil, :trial=>nil, :debug=>nil,
        :quiet=>nil, :verbose=>nil,
        :force=>nil, :multitask=>nil, :skip=>[]
      }
    end

    #
    def initialize_usage
      @usage = OptionParser.new do |usage|
        usage.banner = "Usage: redline [<cycle>:]<phase> [options]"

        usage.on('--trace', "Run in TRACE mode.") do
          #$TRACE = true
          options[:trace] = true
        end

        usage.on('--trial', "Run in TRIAL mode (no disk writes).") do
          #$TRIAL = true
          options[:trial] =true
        end

        usage.on('--debug', "Run in DEBUG mode.") do
          $DEBUG   = true
          $VERBOSE = true  # wish this were called $WARN
          options[:debug] = true  # DEPRECATE
        end

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

        usage.on_tail('--help', "Display this help message.") do
          puts usage
          exit
        end

        usage.on_tail('--config', "Produce a configuration template.") do
          puts application.config_template.to_yaml
          exit
        end
      end
    end

    #def help
    #  usage.help.to_s(:bold=>true)
    #end

    #
    def application
      @application ||= Redline::Application.new(self)
    end

    # parse! ?
    def parse
      @argv ||= ARGV.dup
      @usage.parse!(@argv)
    end

    def arguments
      @argv
    end

    #
    def run
      parse
      if /\.redfile$/ =~ arguments[0]
        job = arguments[1]
        application.runscript(arguments[0], job)
      else
        application.start(arguments)
      end
    end

    #
    def method_missing(s, *a)
      s = s.to_s.chomp('?').to_sym
      if options.key?(s)
        options[s]
      else
        super
      end
    end

  end

end
