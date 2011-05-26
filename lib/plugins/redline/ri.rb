module Redline::Plugins

  # = RI Documentation Plugin
  #
  # The ri documentation plugin provides services for
  # generating ri documentation.
  #
  # By default it generates the ri documentaiton at doc/ri,
  # unless an 'ri' directory exists in the project's root
  # directory, in which case the ri documentation will be
  # stored there.
  #
  # This plugin provides the following cycle-phases:
  #
  #   main:document  - generate ri docs
  #   main:reset     - mark ri docs out-of-date
  #   main:clean     - remove ri docs
  #
  #   site:document  - generate ri docs
  #   site:reset     - mark ri docs out-of-date
  #   site:clean     - remove ri docs
  #
  class RI < Service

=begin
    stop :main, :document
    stop :main, :reset
    stop :main, :clean

    stop :site, :document
    stop :site, :reset
    stop :site, :clean
=end

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Options conform to RedTools::RI class.
    def self.options
      super(RedTools::RI)
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
      @tool ||= RedTools::RI(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
