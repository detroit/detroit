module Promenade::Plugins

  # The ExtConf service utilizes extconf.rb and
  # standard Makefile(s) to compile native extensions.
  #
  # TODO: win32 cross-compile ?
  #
  class ExtConf < Service

=begin
    stop :main, :compile
    stop :main, :reset
    stop :main, :clean
=end

    #available do |project|
    #  # check for make tools
    #end

    #
    def compile
      tool.compile
    end

    #
    def reset
      tool.reset
    end

    #
    def claen
      tool.clean
    end

    #
    def tool
      @tool ||= RedTools::ExtConf.new(options)
    end

    private

    #
    def initialize_requires
      require 'redtools'
    end

  end

end


