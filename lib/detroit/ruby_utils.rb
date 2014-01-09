module Detroit

  ##
  # Methods for working with a Ruby projects.
  #
  module RubyUtils

    def preinitialize
      require 'facets/platform'
    end

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    #
    def project
      @project ||= RubyUtils::Project.lookup
    end

    ## Set project manually.
    ##
    #def project=(proj)
    #  @project = proj
    #end

    # Project metadata.
    #
    # @return [Indexer::Metadata]
    def metadata
      project.metadata
    end

    # Project root directory.
    #
    # @return [Pathname]
    def root
      project.root
    end

  end

end
