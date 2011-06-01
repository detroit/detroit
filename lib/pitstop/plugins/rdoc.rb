module Pitstop::Plugins

  # RDoc documentation plugin generates RDocs for your project.
  #
  # By default it generates the rdoc documentaiton at doc/rdoc,
  # unless an 'rdoc' directory exists in the project's root
  # directory, in which case the rdoc documentation will be
  # stored there.
  #
  # This plugin provides the following cycle-phases:
  #
  #   main:document  - generate rdocs
  #   main:reset     - mark rdocs out-of-date
  #   main:clean     - remove rdocs
  #
  #   site:document  - generate rdocs
  #   site:reset     - mark rdocs out-of-date
  #   site:clean     - remove rdocs
  #
  class RDoc < Service

=begin
    ##
    # Generate rdocs in main cycle.
    # :method: main_document
    stop :main, :document
    stop :main, :reset
    stop :main, :clean

    stop :site, :document
    stop :site, :reset
    stop :site, :clean
=end

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
