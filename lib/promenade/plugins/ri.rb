module Promenade::Plugins

  # = RI Documentation Plugin
  #
  # The ri documentation plugin provides services for
  # generating ri documentation.
  #
  # By default it generates the ri documentaiton at doc/ri,
  # unless an 'ri' directory exists in the project's root
  # directory, in which case the ri documentation will be
  # stored there.
  #
  class RI < Service

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Options conform to RedTools::RI class.
    def self.options
      super(RedTools::RI)
    end

    #
    def document
      tool.document
    end

    #
    def reset
      tool.reset
    end

    #
    def clean
      tool.clean
    end

    #
    def purge
      tool.purge
    end

    private

    #
    def tool
      @tool ||= RedTools::RI(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
