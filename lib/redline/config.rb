require 'facets/boolean'

module Redline

  # Redline configuration. Configuration comes from a main +Redfile+
  # and/or +.redfile+ task files.
  class Config
    #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # File identifier used to find a project's Redfile(s).
    FILE_EXTENSION = "redfile"

    # Current POM::Project object.
    attr :project

    # Service configurations from Redfile or task/*.redfile files.
    # This is a hash of parameters.
    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.
    attr :defaults

    #
    def initialize(project) #, *files)
      @project = project

      #if file = project.config.glob('redline/config.{yml,yaml}').first
      #  conf = YAML.load(File.new(file))
      #else
      #  conf = {}
      #end

      # TODO: Are these still here?
      if file = project.root.glob('.redline/defaults.{yml,yaml}').first ||
                project.config.glob('redline/defaults.{yml,yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end

      @services = {}
      @defaults = {}

      redline_files.each do |file|
        load_redline_file(file)
      end
    end

    #
    def defaults=(hash)
      @defaults = hash.to_h #OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    # If Redfile or .redfile exist, then it is returned.
    # Otherwise all task/*.redfile files.
    def redline_files
      @confg_files ||= (
        files = []
        ## match 'Redfile' or '.redfile' with optional .yml or .yaml
        files += project.root.glob("{,.}#{FILE_EXTENSION}{,.yml,.yaml}", :casefold)
        ## match '.redfile/*.redfile' or 'redfile/*.redfile'
        files += project.root.glob("{,.}redline/*.#{FILE_EXTENSION}", :casefold)
        if files.empty?
          ## try 'task/*.redfile' (OLD SCHOOL)
          files += project.task.glob("*.#{FILE_EXTENSION}")
        end
        files = files.select{ |f| File.file?(f) }
      )
    end

    # If using a Redfile and want to import antoher file then use
    # +import:+ entry.
    #
    # Use the :defaults: entry to add service defaults. Note that these
    # are presently NOT per-file, but are merged together for all redfiles.
    def load_redline_file(file)
      dir  = File.dirname(file)
      text = File.read(file).strip

      ## if yaml vs. ruby file
      if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
        data = parse_redline_file_yaml(text, file)
      else
        data = parse_redline_file_ruby(text, file)
      end    

      ## extract defaults
      if defaults = data.delete('defaults')
        @defaults.merge!(defaults)
      end

      ## import other files
      if import = data.delete('import')
        [import].flatten.each do |glob|
          pattern = File.join(dir,glob)
          Dir[pattern].each{ |f| load_redline_file(f) }
        end
      end

      ## require plugins
      if plugins = data.delete('plugins')
        [plugins].flatten.each do |file|
          #pattern = File.join(dir,glob)
          #Dir[pattern].each{ |f| require(f) }
          require file
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
    # setter notation, instead of instance_eval. The former is the most robust,
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

