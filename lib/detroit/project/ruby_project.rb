module Detroit

  ##
  # Ruby Project class.
  #
  class RubyProject < Project

    #
    def self.lookup
      dir = Dir.pwd
      while dir != '/' #&& dir != $HOME
        return new(dir) if project?(dir)
        dir = File.dirname(dir)
      end
      return nil
    end

		# Determine if a directory is a Ruby project.
		def self.project?(root)
		  Dir["{*,}.gemspec"].first
		end

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
