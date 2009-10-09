require 'path/store'

module Syckle

  # Syckle master configuration. Configuration settings load
  # from a YStore located at '.config/syckle/'.
  #
  # TODO: Allow +automatic+ to be a list of serive names to active
  #       automatic mode for.
  #
  class Config

    #
    def initialize(project)
      #@project = project

      #initialize_defaults

      # If YAML file is used.
      #project.config.glob('syckle{,.yml,.yaml}').each do |path|
      #  conf = conf.merge(YAML.load(File.new(path))) if path.file?
      #end

      @store = Path::Store.new(project.config + 'syckle')
    end

    #def initialize_defaults
    #  @automatic = false
    #  @auto_omit = []
    #end

    # Use automatic services feature?
    # If set to +true+, all services with autorun modes will
    # run if their autorun criteria is met.
    # Or this can be set to a list of service names for which
    # autorub mode will apply.
    def automatic
      @store.automatic
    end

    # Alias for #automatic.
    alias_method :automatic?, :automatic

    # Services to omit from automatic execution. If automatic
    # is set to true, the manual setting can be used to exclude
    # specify services for autorunning.
    # Should be an array of service names (class basenames).
    def manual
      @store.manual || []
    end

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for autorun mode.
    def defaults
      @store.defaults || {}
    end

  end

end

