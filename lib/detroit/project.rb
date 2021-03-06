module Detroit

  require 'indexer'

  def self.project(root)
    Project.factory(root)
  end

  ##
  # Base class for more specific Project types.
  #
  class Project

		# FIXME: Lookup root directory. How?
		def self.root
		  Dir.pwd 
		end

    #
    def self.lookup
      dir = Dir.pwd
      while dir != '/' #&& dir != $HOME
        return new(dir) if project?(dir)
        dir = File.dirname(dir)
      end
      return nil
    end

    # Get a new project instance based on criteria of the project.
    # For instance a project with a `*.gemspec` is recognized as a
    # Ruby project and thus returns an instance of {RubyProject}.
    #
    # @return [Project]
    def self.factory(root)
      if RubyProject.project?(root)
        RubyProject.new(root)
      else
        Project.new(root)
      end
    end

    #
    def self.memo
      @memo ||= {}
    end

    # Override new in order to memoize projects based on root directory.
    def self.new(root)
      memo[root] ||= super(root)
    end

    # Initialize new instance of Project.
    #
    # @param [String,Pathname] root
    #   Root directory of project.
    #
    # @return [Pathname]
    def initialize(root)
      @root = Pathname.new(root)
      @log  = @root + 'log'
    end

    # Root directory.
    #
    # @return [Pathname]
    attr :root

    # Log directory. By defaul this is `{root}/log/`.
    attr :log

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
    # instance, and if possible it should respond to `#to_h` method.
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

  ##
  # Ruby Project class.
  #
  class RubyProject < Project

		# Determine if a directory is a Ruby project by
    # looking for a .gemspec file.
    #
    # @todo While this will work well in the vase majority of
    #       cases, there may be a few outlays.
    #
		def self.project?(root)
		  Dir[File.join(root, "{*,}.gemspec")].first
		end

    #
    #def initialize(root)
    #  super(root)
    #end

    #
    def metadata
      @metadata ||= (
        if index_file
          Indexer::Metadata.open(root)
        elsif file = gemspec_file
          Indexer::Metadata.from_gemspec(file)
        else
          super # TODO: what metadata?
        end
      )
    end

    #
    def index_file
		  Dir[File.join(root, ".index")].first
    end

    #
    def gemspec_file
		  Dir[File.join(root, "{*,}.gemspec")].first
    end

  end

end
