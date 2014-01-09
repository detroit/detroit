module Detroit

  require 'indexer'

  def self.project(root)
    Project.factory(root)
  end

  ##
  # Base class for more specific Project types.
  #
  class Project

    # Get a new project instance based on criteria of the project.
    # For instance a project with a `*.gemspec` is recognized as a
    # Ruby project and thus returns an instance of {RubyProject}.
    #
    # @return [Project]
    def self.factory(root)
      if ruby_project?(root)
        RubyProject.new(root)
      else
        Project.new(root)
      end
    end

    # Initialize new instance of Project.
    #
    # @param [String,Pathname]
    #   Root directory of project.
    #
    # @return [Pathname]
    def initialize(root)
      @root = Pathname.new(root)
    end

    # Root directory.
    #
    # @return [Pathname]
    attr :root

    # Detroit configuration for project.
    #
    # @return [Config]
    def config
      @config ||= Config.new(root)
    end

    # TODO: Indexer's Loadable module is confusing!!!

    # Access to project metadata. Metadata is handled by Indexer.
    # If a specific project type has different needs then override
    # this method. The return value should work akin to an OpenStruct
    # instance.
    #
    # @return [Indexer::Metadata]
    def metadata
      @metadata ||= Indexer::Metadata.open(root)
    end

    # If method is missing see if it is a piece of metadata.
    def method_missing(s, *a, &b)
      super(s, *a, &b) unless a.empty?
      super(s, *a, &b) if block_given?
      metadata.send(s)
    end

  end

end
