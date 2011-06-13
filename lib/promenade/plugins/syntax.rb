module Promenade::Plugins

  # The Syntax service simply checks all Ruby code for
  # syntax errors. It's a rather trivial tool, and is
  # here simply for example sake.
  #
  class Syntax < Service

=begin
    stop :main, :analyze
=end

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Options conform to RedTools::Syntax class.
    def self.options
      super(RedTools::Syntax)
    end

    #
    def analyze
      tool.run
    end

    private

    #
    def tool
      @tool ||= RedTools::Syntax(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
