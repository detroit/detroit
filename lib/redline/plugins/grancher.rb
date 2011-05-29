module Redline::Plugins

  # = Grancher Plugin
  #
  # This plugin copies designated files to a git branch.
  # This is useful for dealing with situations like GitHub's
  # gh-pages branch for hosting project websites.[1]
  #
  # [1] A poor design copied from the Git project itself.
  #
  class Grancher < Service

    # Options conform to RedTools::Grancher class.
    def self.options
      super(RedTools::Grancher)
    end

    # TODO: should grancher transfer be a `generate` stop?
    def pre_publish
      tool.transfer
    end

    #
    def publish
      tool.publish
    end

    private

    #
    def tool
      @tool ||= RedTools::Grancher(@options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

