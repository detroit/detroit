#require 'path/store'
require 'facets/ostruct'

module Syckle

  # Syckle master configuration. Configurations loads from
  # master +Syckfile+ and.or +.syckle+ subordinate files.
  #
  # TODO: Allow +automatic+ to be a list of serive names to active automatic mode for.

  class Config

    instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Current POM::Project object.

    attr :project

    # Use automatic services feature? If set to +true+,
    # all services with autorun modes will run if their
    # autorun criteria is met. Or this can be set to a
    # list of service names for which autorun mode will
    # apply.

    attr :automatic

    # Services to omit from automatic execution. If automatic
    # is set to true, the manual setting can be used to exclude
    # specify services for autorunning.
    # Should be an array of service names (class basenames).

    attr :manual

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for autorun mode.

    attr :defaults

    # Service configurations. This is a hash of parameters.

    attr :services

    #
    def initialize(project) #, *files)
      @project = project
      @services = {}

      files = config_files
      files.each do |file|
        load_syckle_file(file)
      end
    end

    #
    def config_files
      @confg_files ||= (
        files = []
        if project.root.glob('Syckfile').first
          files += project.root.glob('Syckfile')
        else
          files += project.task.glob('*.syckle')
          files += project.script.glob('*.syckle')
        end
        files = files.select{ |f| File.file?(f) }
      )
    end

    #
    def load_syckle_file(file)
      text = File.read(file)

      #if /\A---/ =~ text
        edit = ERB.new(text).result(binding).strip       
        data = YAML.load(edit) || {}
        #data = YAMLParser.load(text, :project => @project, nil => @project.metadata)
      #else
      #  data = RAMLParser.load(text, :project => @project)
      #end

      self.automatic = data.delete('automatic') if data.key?('automatic')
      self.manual    = data.delete('manual')    || []
      self.defaults  = data.delete('defaults')  || {}

      self.services.update(data)
    end

    # Alias for #automatic.

    def automatic? ; @automatic ; end

    # Are there any manual entries?

    def manual?
      !@manual.empty?
    end

    #
    def automatic=(value)
      warn "Syckle automatic mode set multiple times." unless @automatic.nil?
      @automatic = value
    end

    #
    def manual=(value)
      @manual = [value].flatten.compact.uniq
    end

    #
    def defaults=(hash)
      @defaults = OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    #
    #def services=(hash)
    #  @services = hash
    #end

    #
    #def to_h
    #  h = {}; each{ |k,v| h[k] = v }; h
    #end

    #
    def method_missing(sym, *args)
      super unless args.empty?
      project.metadata.__send__(sym) #if project.metadata.respond_to?(sym)
    end

  end

end





=begin
  # Syckle master configuration. Configuration settings load
  # from a YStore located at '.config/syckle/'.
  #
  # TODO: Allow +automatic+ to be a list of serive names to active
  #       automatic mode for.
  #
  class Config

    attr_accessor :services

    # Use automatic services feature?
    # If set to +true+, all services with autorun modes will
    # run if their autorun criteria is met.
    # Or this can be set to a list of service names for which
    # autorub mode will apply.

    attr_accessor :automatic

    # Services to omit from automatic execution. If automatic
    # is set to true, the manual setting can be used to exclude
    # specify services for autorunning.
    # Should be an array of service names (class basenames).

    attr_accessor :manual

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for autorun mode.

    attr_accessor :defaults

    # Alias for #automatic.

    alias_method :automatic?, :automatic

    # Alias for #manual.

    alias_method :manual?, :manual

    #

    def initialize(project)
      @services  = load_service_configs(project)
      @automatic = services.delete('automatic') || {}  #if @services.key?('automatic')
      @manual    = services.delete('manual')    || {}  #if @services.key?('manual')
      @defaults  = services.delete('defaults')  || {}  #if @services.key?('defaults')
    end

  private

    # Load service configs for a select set of syckle scripts/tasks.

    def load_service_configs(project)
      raise "No syckle files defined." if config_files.empty?

      config_files.each do |file|

      srvcfg = files.inject({}) do |cfg, file|
        tmp = TMP.new(project.metadata)
        erb = ERB.new(File.read(file))
        txt = erb.result(tmp._binding).strip
        if /\A---/ =~ txt
          yml = YAML.load(txt) || {}
        else
          yml = Syckfile::Parser.load(txt)
        end
        cfg.update(yml)
      end
    end

    #
    def config_files
      @confg_files ||= (
        files = []
        if project.root.glob('Syckfile')
          files += project.root.glob('Syckfile')
        else
          files += project.task.glob('*.syckle')
          files += project.script.glob('*.syckle')
        end
        files = files.select{ |f| File.file?(f) }
      )
    end

  end
=end

