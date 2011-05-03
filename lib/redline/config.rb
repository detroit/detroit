require 'facets/boolean'
#require 'path/store'

module Redline

  # Redline configuration. Configuration comes from a main +Syckfile+
  # and/or +.red+ task files, and configuration options defined
  # in a path store in the project's config directory (eg. <tt>.config/red/</tt>).
  
  class Config
    #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    FILE = 'Syckfile'

    # Current POM::Project object.
    attr :project

    # Service configurations from Syckfile or task/*.red files.
    # This is a hash of parameters.
    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.
    attr :defaults

    #
    def initialize(project) #, *files)
      @project = project

      if file = project.config.glob('redline/config.{yml,yaml}').first
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

      if file = project.config.glob('redline/defaults.{yml,yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end

      @services = {}

      redline_files.each do |file|
        load_redline_file(file)
      end
    end

    #
    def defaults=(hash)
      @defaults = hash.to_h #OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    # If Syckfile or .syckfile exist, then it is returned.
    # Otherwise all task/*.red files.
    def redline_files
      @confg_files ||= (
        files = project.root.glob("{,.}#{FILE}{,.yml,.yaml}", :casefold)
        if files.empty?
          files += project.task.glob('*.red')
        end
        files = files.select{ |f| File.file?(f) }
      )
    end

    # If using Syckfile and want to import task/*.red
    # files then use +import:+ entry. 
    def load_redline_file(file)
      dir  = File.dirname(file)
      text = File.read(file).strip

      # if yaml vs. ruby file
      if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
        data = parse_redline_file_yaml(text, file)
      else
        data = parse_redline_file_ruby(text, file)
      end

      # Import other files. This is useful when using the Syckfile.
      if import = data.delete('import')
        [import].flatten.each do |glob|
          pattern = File.join(dir,glob)
          Dir[pattern].each{ |f| load_redline_file(f) }
        end
      end

      @services.update(data)
    end

    #
    def parse_redline_file_yaml(text, file)
      edit = ERB.new(text).result(scope.binding).strip
      YAML.load(edit) || {}
    end

    #
    def parse_redline_file_ruby(text, file)
      parser = Parser.new(file, text)
      parser.__services__
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

    # TODO: This needs to be a subclass of BasicObject or it needs to use 
    # setter notation, instead of instance_eval. The later is the most robust,
    # but the later can work if we are very explict about methods in the context.
    class Parser
      public_instance_methods.each{ |m| undef_method m unless /^(__|instance_)/ =~ m.to_s }
      #private_instance_methods.each{ |m| undef_method m unless /^(__|initialize)/ =~ m.to_s }

      def self.parse(&block)
        new(&block).__services__
      end

      attr :__services__

      def initialize(file=nil, text=nil)
        @__services__ = {}
        text = File.read(file) if file unless text
        instance_eval(text) if text
      end

      def method_missing(service, name=nil, *args, &block)
        name = (name || service).to_s
        @__services__[name] = SettingsParser.parse(&block)
        @__services__[name]['service'] = service.to_s
        @__services__[name]
      end
    end

    # TODO: This needs to be a subclass of BasicObject or it needs to use 
    # setter notation, instead of instance_eval. The later is the most robust,
    # but the later can work if we are very explict about methods in the context.
    class SettingsParser
      #public_instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }
      public_instance_methods.each{ |m| undef_method m unless /^(__|instance_|p$)/ =~ m.to_s }
      #private_instance_methods.each{ |m| p m; undef_method m unless /^(__|initialize$|p$|puts$)/ =~ m.to_s }

      def self.parse(&block)
        new(&block).__settings__
      end

      attr :__settings__

      def initialize(&block)
        @__settings__ = {}
        instance_eval(&block) if block
      end

      def method_missing(name, *args, &block)
        value = args.first
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
