require 'syckle/application'
require 'optparse'

module Syckle

  # = Commandline Interface
  #
  class CLI

    #
    attr :usage

    #
    attr :options

    #
    def initialize
      @usage   = OptionParser.new

      @options = {
        :noop=>nil,:debug=>nil,:quiet=>nil,:verbose=>nil,
        :force=>nil,:multitask=>nil,:skip=>[]
      }

      usage.banner = "Usage: syckle [<cycle>:]<phase> [options]"

      usage.on('--trace', "Trace execution") do
        options[:debug]   = true
        options[:verbose] = true
      end

      usage.on('--debug', "Run in DEBUG mode.") do
        options[:debug] = true
      end

      usage.on('-n', '--noop', "No disk writes.") do  # dryrun
        options[:noop] = true
      end

      usage.on('--verbose', "Provided extra output.") do
        options[:verbose] = true
      end

      usage.on('--dryrun', "No disk writes and verbose.") do  # dryrun
        options[:noop] = true
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

    #def help
    #  usage.help.to_s(:bold=>true)
    #end

    #
    def application
      @application ||= Syckle::Application.new(self)
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
      if /\.syckle$/ =~ ARGV[0]
        job = ARGV[1]
        application.runscript(ARGV[0], job)
      else
        application.start
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
