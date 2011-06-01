module Pitstop::Plugins

  # RDoc documentation plugin generates RDocs for your project.
  #
  # By default it generates the rdoc documentaiton at doc/rdoc,
  # unless an 'rdoc' directory exists in the project's root
  # directory, in which case the rdoc documentation will be
  # stored there.
  #
  class RDoc < Service

    # TODO: IMPROVE
    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Options conform to RedTools::RDoc class.
    def self.options
      super(RedTools::RDoc)
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
      @tool ||= RedTools::RDoc(@options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
