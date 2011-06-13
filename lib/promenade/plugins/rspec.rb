module Promenade::Plugins

  # RSpec Service runs RSpec specifications and also
  # generates RSpec documentation.
  #
  #--
  # TODO: A special option to deactivate document stop?
  #++
  class RSpec < Service

=begin
    stop :main, :test
    stop :main, :document
    stop :site, :document
=end

    #
    #available do |project|
    #  begin
    #    #require 'rspec' # can we do this?
    #    true
    #  rescue LoadError
    #    false
    #  end
    #end

    # Options conform to RedTools::RSpec class.
    def self.options
      super(RedTools::RSpec)
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
      @tool ||= RedTools::RSpec(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

