require 'facets/boolean'
#require 'path/store'

module Syckle

  # Syckle configuration. Configuration comes from a main +Syckfile+
  # and/or +.syckle+ task files, and configuration options defined
  # in a path store in the project's config directory (eg. <tt>.config/syckle/</tt>).
  
  class Config
    instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Current POM::Project object.

    attr :project

    # Service configurations from Syckfile or task/*.syckle files.
    # This is a hash of parameters.

    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.

    attr :defaults

    #

    def initialize(project) #, *files)
      @project = project

      if file = project.config.glob('syckle/config.{yml,yaml}').first
        conf = YAML.load(File.new(file))
      else
        conf = {}
      end

      #if conf['automatic'].nil?
      #  self.automatic = true
      #else
      #  self.automatic = conf['automatic']
      #end

      #self.standard  = conf['standard'] || []

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

    #

    def defaults=(hash)
      @defaults = hash.to_h #OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    # If Syckfile or .syckfile exist, then it is returned.
    # Otherwise all task/*.syckle files.

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

    # If using Sycjkfile and want to import task/*.syckle
    # files then use +import:+ entry. 

    def load_syckle_file(file)
      text = File.read(file).strip

      if /\A---/ =~ text
        begin
          edit = ERB.new(text).result(scope.binding).strip
        rescue => err
          raise err if $DEBUG
          abort "#{File.basename(file)}: #{err}"
        end
        data = YAML.load(edit) || {}
      else
        parser = Parser.new
        parser.instance_eval(text, file)
        data = parser.__services__
      end

      ## automatics can be defined in the syckle files (TODO: Is this prudent?)
      ##self.automatic = data.delete('automatic') if data.key?('automatic')
      #self.standard  = data.delete('standard')  if data.key?('standard')

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
    def scope
      @scope ||= Scope.new(project)
    end

    #
    #def method_missing(sym, *args)
    #  super unless args.empty?
    #  project.metadata.__send__(sym) #if project.metadata.respond_to?(sym)
    #end

    #
    class Parser
      public_instance_methods.each{ |m| private m unless /^(__|instance_)/ =~ m.to_s }

      def self.parse(&block)
        new(&block).__services__
      end

      attr :__services__

      def initialize()
        @__services__ = {}
      end

      def method_missing(service, name=nil, *args, &block)
        name = (name || service).to_s
        @__services__[name] = SettingsParser.parse(&block)
        @__services__[name]['service'] = service.to_s
        @__services__[name]
      end
    end

    #
    class SettingsParser
      public_instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

      def self.parse(&block)
        new(&block).__settings__
      end

      attr :__settings__

      def initialize(&block)
        @__settings__ = {}
        instance_eval(&block) if block
      end

      def method_missing(name, value, *args, &block)
        if block_given?
          @__settings__[name.to_s] = SettingsParser.parse(&block)
        else
          @__settings__[name.to_s] = value
        end
      end
    end

    #
    class Scope
      #
      attr :project

      #
      def initialize(project)
        @project = project
      end

      #
      def method_missing(sym, *args)
        super(sym, *args) unless args.empty?
        @project.metadata.__send__(sym) #if project.metadata.respond_to?(sym)
      end

      public :binding
    end

  end

end

