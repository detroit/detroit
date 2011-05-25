module Redline::Plugins

  # = Gem Builder Plugin
  #
  # This plugin generate a gem package.
  #
  class Gem < Service

    #pre_stop :main, :package do
    #  pre_package
    #end

    stop :main, :package
    stop :main, :release
    stop :main, :clean

    # Options conform to RedTools::RDoc class.
    def self.options
      super(RedTools::Gem)
    end

    #
    #def pre_package
    #  tool.spec
    #end

    #
    def package
      tool.package
    end

    #
    def release
      tool.push
    end

    #
    def clean
      tool.clean
    end

    private

    #
    def tool
      @tool ||= RedTools::Gem(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
