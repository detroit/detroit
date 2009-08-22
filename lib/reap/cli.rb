require 'clio/usage'

module Reap

  # = Commandline Interface
  #
  # TODO: skip should be a multiple argument option, but Clio is having issues with that right now.
  # For now we can just use a ';' to separate service names.
  #
  class CLI #< ::Clio::Commandline  #::Ratch::Commandline

    def initialize
      usage.opt('--help'         , "Display this help message.")
      usage.opt('--trace'        , "Trace execution")
      usage.opt('--debug'        , "Run in DEBUG mode.")
      usage.opt('--pretend -p'   , "No disk writes.")  # dryrun
      usage.opt('--quiet   -q'   , "Run silently.")
      usage.opt('--verbose'      , "Provided extra output.")
      usage.opt('--force'        , "Force operations.")
      usage.opt('--multitask -m' , "Run in parallel.")

      usage.option('skip', 's') do
        desc "Skip service(s). Separate multiple serives with a semicolon."
        arg "VALUE"
        multiple  # FIXME: multiple is not working!!! fix Clio or switch to optparser
      end
    end

    def usage
      @usage ||= Clio::Usage.new
    end

    def cli
      @cli ||= parse
    end

    def help
      usage.help.to_s(:bold=>true)
    end

    def parse
      @cli = usage.parse(ARGV)
    end

    def dryrun? ; pretend? ; end

    #
    def method_missing(s, *a)
      cli.send(s, *a)
    end
  end

end

