module Pitstop::Plugins

  # The Gem service is used to generate a gem package
  # and dsitribute it to a Gemcutter service. It can
  # also be used to automatically generate a gemspec
  # from project metadata.
  #
  # TODO: Should project metadata come from canonical only? Or is using POM inference okay?
  class Gem < Service

=begin
    #pre_stop :main, :package do
    #  pre_package
    #end

    stop :main, :package
    stop :main, :release
    stop :main, :clean
=end

    # Options conform to RedTools::RDoc class.
    def self.options
      super(RedTools::Gem)
    end

    # TODO: Use pre-package for creating gemspec?
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
