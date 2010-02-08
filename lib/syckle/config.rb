require 'facets/boolean'
#require 'path/store'

module Syckle

  # Syckle configuration. Configuration comes from a main +Syckfile+
  # and/or +.syckle+ task files, and configuration options defined
  # in a path store in the project's config directory (eg. <tt>.config/syckle/</tt>).
  #
  # TODO: Allow +automatic+ to accept a list of serives to limit automatic mode.

  class Config

    instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Current POM::Project object.

    attr :project

    # Service configurations. This is a hash of parameters.

    attr :services

    # Use automatic services feature? If set to +true+,
    # all services with autorun modes will run if their
    # autorun criteria is met. Or this can be set to a
    # list of service names for which autorun mode will
    # apply.
    #
    # Default is +true+. Use +false+ to deactivate.

    attr :automatic

    # Services to omit from automatic execution. If automatic
    # is set to +true+ (the default), the +standard+ setting can
    # be used to exclude specific services from auto-execution. 

    attr :standard

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for autorun mode.

    attr :defaults

    #

    def initialize(project) #, *files)
      @project = project

      if file = project.config.glob('syckle/config.{yml,yaml}').first
        conf = YAML.load(File.new(file))
      else
        conf = {}
      end

      if conf['automatic'].nil?
        self.automatic = true
      else
        self.automatic = conf['automatic']
      end

      self.standard  = conf['standard'] || []

      if file = project.config.glob('syckle/defaults.{yml,yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end

      @services = {}

      syckle_files.each do |file|
        load_syckle_file(file)
      end
    end

    # Alias for #automatic.

    def automatic? ; @automatic ; end

    # Are there any manual entries?

    def standard?
      !standard.empty?
    end

    #

    def automatic=(value)
      @automatic = value.to_b
    end

    #

    def standard=(value)
      @standard = [value].flatten.compact.uniq
    end

    #

    def defaults=(hash)
      @defaults = hash.to_h #OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    #

    def syckle_files
      @confg_files ||= (
        files = []
        if project.root.glob('{Syckfile,.syckle}').first
          files += project.root.glob('{Syckfile,.syckle}')
        else
          files += project.task.glob('*.syckle')
          #files += project.script.glob('*.syckle')
        end
        files = files.select{ |f| File.file?(f) }
      )
    end

    #

    def load_syckle_file(file)
      text = File.read(file)

      begin
        edit = ERB.new(text).result(binding).strip
      rescue => err
        raise err if $DEBUG
        abort "#{File.basename(file)}: #{err}"
      end

      data = YAML.load(edit) || {}

      # automatics can be defined in the syckle files (TODO: Is this prudent?)
      self.automatic = data.delete('automatic') if data.key?('automatic')
      self.standard  = data.delete('standard')  if data.key?('standard')

      # We import other files. This is most useful when using a Syckfile.
      if import = data.delete('import')
        [import].flatten.each do |glob|
          Dir[glob].each do |f|
            load_syckle_file(f)
          end
        end
      end


      @services.update(data)
    end

    #
    def method_missing(sym, *args)
      super unless args.empty?
      project.metadata.__send__(sym) #if project.metadata.respond_to?(sym)
    end

  end

end

