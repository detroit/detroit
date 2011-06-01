module Pitstop::Plugins

  # = Test::Unit Plugin via testrb
  #
  # This service plugin runs your TestUnit/MiniTest unit tests
  # via `ruby` command line.
  #
  # TODO: How to abort track if fail?
  #
  class Testrb < Service

=begin
    stop :main, :test
=end

    #available do |project|
    #  !Dir['test/**/*.rb'].empty?
    #end

    # Options conform to RedTools::Testrb class.
    def self.options
      super(RedTools::Testrb)
    end

    #
    def test
      tool.run
    end

    private

    #
    def tool
      @tool ||= RedTools::Testrb(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

