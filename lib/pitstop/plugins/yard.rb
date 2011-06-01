module Pitstop::Plugins

  # Yard documentation service generates YARD docs for your project.
  #
  # By default it generates the yard documentaiton at doc/yard,
  # unless a 'yard' directory exists in the project's root
  # directory, in which case the documentation will be stored there.
  #
  # This plugin provides the following track-stops:
  #
  #   main:document  - generate yardocs
  #   main:reset     - mark yardocs out-of-date
  #   main:clean     - remove yardocs
  #
  #   site:document  - generate yardocs
  #   site:reset     - mark yardocs out-of-date
  #   site:clean     - remove yardocs
  #
  class Yard < Service

=begin
    stop :main, :document
    stop :main, :reset
    stop :main, :clean

    stop :site, :document
    stop :site, :reset
    stop :site, :clean
=end

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
      @tool ||= RedTools::Yard(@options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

