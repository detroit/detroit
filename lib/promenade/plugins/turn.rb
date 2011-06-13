module Promenade::Plugins

  # The Turn service runs TestUnit/MiniTest unit tests using
  # the +turn+ tool.
  #
  class Turn < Service

    #available do |project|
    #  !Dir['test/**/*.rb'].empty?
    #end

    # Options conform to RedTools::Turn class.
    def self.options
      super(RedTools::Turn)
    end

    #
    def test
      tool.run
    end

    #
    def document
      tool.document
    end

    private

    #
    def tool
      @tool ||= RedTools::Turn(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

