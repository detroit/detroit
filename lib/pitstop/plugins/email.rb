module Pitstop::Plugins

  # The Announce service supports the @promote@ action
  # to send out a project annoucement to a set of email
  # addresses.
  #
  # By default it generates a <i>Release Announcement</i> based
  # on a projects README.* file.
  class Email < Service

    def announce
      tool.announce
    end

    def tool
      @tool ||= RedTools::EMail.new(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end


