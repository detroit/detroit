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

=begin
    # TODO: should grancher transfer be a `generate` stop?
    pre_stop :main, :release do
      transfer
    end

    stop :main, :release

    # TODO: should grancher transfer be a `generate` stop?
    pre_stop :site, :release do
      transfer
    end

    stop :site, :release
=end

    # Options conform to RedTools::Grancher class.
    def self.options
      super(RedTools::Grancher)
    end

    # TODO: should grancher transfer be a `generate` stop?
    def pre_release
      tool.transfer
    end

    #
    def release
      tool.release
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

