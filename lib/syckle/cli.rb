require 'optparse'

module Syckle

  # = Commandline Interface
  #
  class CLI

    attr :usage
    attr :options

    def initialize
      @usage   = OptionParser.new
      @options = {
        :trace=>nil,:debug=>nil,:pretend=>nil,:quiet=>nil,:verbose=>nil,
        :force=>nil,:multitask=>nil,:skip=>[]
      }

      usage.banner = "Usage: syckle [<cycle>:]<phase> [options]"

      usage.on('--trace', "Trace execution") do
        options[:trace] = true
      end

      usage.on('--debug', "Run in DEBUG mode.") do
        options[:debug] = true
      end

      usage.on('-p', '--pretend', "No disk writes.") do  # dryrun
        options[:pretend] = true
      end

      usage.on('-q', '--quiet', "Run silently.") do
        options[:quiet] = true
      end

      usage.on('--verbose', "Provided extra output.") do
        options[:verbose] = true
      end

      usage.on('--force', "Force operations.") do
        options[:multitask] = true
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
    end

    #def help
    #  usage.help.to_s(:bold=>true)
    #end

    def parse
      usage.parse!(ARGV)
    end

    def dryrun?
      pretend?
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
