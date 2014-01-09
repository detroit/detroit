module Detroit

  # Determine if a directory is a Ruby project.
  def Project.ruby_project?(root)
    Dir["{*,}.gemspec"].first
  end

  ##
  # Ruby Project class.
  #
  class RubyProject < Project

    #
    def initialize(root)
      super(root)
    end

    # @todo Import gemspec if no .index file exists.
    def metadata
      super
    end

  end

end
