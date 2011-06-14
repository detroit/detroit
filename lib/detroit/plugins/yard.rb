module Detroit::Plugins

  # Yard documentation service generates YARD docs for your project.
  #
  # By default it generates the yard documentaiton at doc/yard,
  # unless a 'yard' directory exists in the project's root
  # directory, in which case the documentation will be stored there.
  #
  # This plugin provides the following stops:
  #
  #   document  - generate yardocs
  #   reset     - mark yardocs out-of-date
  #   purge     - remove yardocs
  #
  class Yard < Service

    # Make sure YARD is available.
    available do |project|
      #!project.metadata.loadpath.empty?
      begin
        require 'yard'
        true
      rescue LoadError
        false
      end
    end

    # Options conform to RedTools::Yard class.
    def self.options
      super(RedTools::Yard)
    end

    # Generate YARD documentation. 
    def document
      tool.document
    end

    # Mark the YARD documentation as out-of-date.
    def reset
      tool.reset
    end

    # @note this doesn't actually do anything presently
    #   but it has been added should the tool change.
    def clean
      tool.clean
    end

    # Remove the YARD documentation.
    def purge
      tool.purge
    end

    private

    #
    def tool
      @tool ||= RedTools::Yard(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

