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

    ##
    # Ruby Project class.
    #
    class Project < Detroit::Project

      #
      def initialize(root)
        require 'indexer'
        super(root)
      end

      # TODO: Indexer's Loadable module is confusing!!!

      # Access to project metadata.
      #
      # @todo Import gemspec if no .index file exists.
      #
      # @return [Indexer::Metadata]
      def metadata
        @metadata ||= (
          Indexer::Metadata.open(root)
        )
      end

      # If method is missing see if it is a piece of metadata.
      def method_missing(s, *a, &b)
        super(s, *a, &b) unless a.empty?
        super(s, *a, &b) if block_given?
        metadata.send(s)
      end

    end

  end

end
