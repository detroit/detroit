module Detroit::Plugins

  #
  class VClog < Service

    ## Make sure vclog.rb is available.
    #available do |project|
    #  #!project.metadata.loadpath.empty?
    #  begin
    #    require 'vclog'
    #    true
    #  rescue LoadError
    #    false
    #  end
    #end

    # Options conform to RedTools::VClog class.
    def self.options
      super(RedTools::VClog)
    end

    # Run VClog.
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
      @tool ||= RedTools::VClog(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

