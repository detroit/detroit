module Pitstop::Plugins

  # The Developmer's Notes tool goes through you source files
  # and compiles a list of any labeled comments. Labels are
  # single word prefixes to a comment ending in a colon.
  # For example, you might note somewhere in your code:
  #
  # By default this label supports the TODO, FIXME, OPTIMIZE
  # and DEPRECATE.
  #
  # Output is a set of files in HTML, XML and RDoc's simple
  # markup format. This plugin can run automatically if there
  # is a +notes/+ directory in the project's log directory.
  #
  #--
  # TODO: Should this service be part of the +site+ track?
  #++
  class DNote < Service

=begin
    stop :main, :document
    stop :main, :reset
    stop :main, :clean
=end

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Options conform to RedTools::Syntax class.
    def self.options
      super(RedTools::DNote)
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
      @tool ||= RedTools::DNote(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end
