require_relative '../project'

module Detroit

  ##
  # Methods for working with a Ruby projects.
  #
  module RubyUtils

    # TODO: Rename to preinitialize.
    def prerequisite
      require 'facets/platform'
    end

    # Current platform.
    def current_platform
      Platform.local.to_s
    end


    ## Set project manually.
    ##
    #def project=(proj)
    #  @project = proj
    #end

  end

end
