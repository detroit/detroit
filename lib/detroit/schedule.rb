module Detroit

  # Assembly encapsulates a `Assembly` file and it's service instance
  # configurations.
  class Assembly

    # Load Scedule file.
    def self.load(input)
      new(input)
    end

    # Hash table of services.
    attr :services

    private

    # Initialize new Assembly instance.
    def initialize(file, options={})
      @project = options[:project]

      @services = {}

      @file = (String === file ? File.new(file) : file)

      case File.extname(@file.path)
      when '.rb'
        instance_eval(@file.read, @file.path)
      when '.yml', '.yaml'
        @services = YAML.load(erb(@file.read))
      else
        text = @file.read
        if /^---/ =~ text
          @services = YAML.load(erb(text))
        else
          instance_eval(text, @file.path)
        end
      end
    end

    # Define a service.
    def service(name, settings={}, &block)
      if block
        block_context = BlockContext.new(&block)
        settings = block_context.settings
      end
      @services[name.to_s] = settings.rekey(&:to_s)
    end

    # Access to project data.
    #
    # NOTE: Thinking that the project should be relative
    # to the Routine file itself, unless a `project` is passed
    # in manually through the initializer. In the mean time,
    # the project is just relative to the current working directory.
    #
    # TODO: Make configurable and use .ruby by default ?
    def project
      @project ||= POM::Project.find #(file_directory)
    end

    # Capitalized service names called as methods
    # can also define a service.
    def method_missing(sym, *args, &block)
      service_class = sym.to_s
      case service_class
      when /^[A-Z]/
        if Hash === args.last
          args.last[:service] = service_class
        else
          args << {:services=>service_class}
        end
        case args.first
        when String, Symbol
          name = args.first
        else
          name = service_class.to_s.downcase
        end
        service(name, *args, &block)
      else
        super(sym, *args, &block)
      end
    end

    private

    # Process Routine document via ERB.
    def erb(text)
      context = ERBContext.new(project)
      ERB.new(text).result(context.__binding__)
    end

    # ERBContext provides the clean context to process a Routine
    # as an ERB template.
    class ERBContext
      #
      def initialize(project)
        @project = project
      end

      # Access to a clean binding.
      def __binding__
        binding
      end

      # Provide access to project data.
      def project
        @project
      end

      #
      def method_missing(name, *args)
        if project.respond_to?(name)
          project.__send__(name, *args)
        elsif project.metadata.respond_to?(name)
          project.metadata.__send__(name, *args)
        else
          super(name, *args)
        end
      end
    end

    #
    class BlockContext
      #
      attr :settings

      #
      def initialize(&block)
        @settings = {}
        if block.arity == 0
          instance_eval(&block)
        else
          block.call(self)
        end
      end

      #
      def set(name, value=nil, &block)
        if block
          block_context = BlockContext.new
          block.call(block_context)
          @settings[name.to_s] = block_context.settings
        else
          @settings[name.to_s] = value
        end
      end

      #
      def method_missing(symbol, value=nil, *args)
        case name = symbol.to_s
        when /=$/
          @settings[name.chomp('=')] = value
        else
          super(symbol, value=nil, *args)
        end
      end
    end

  end

  # NOTE: This is problematic, because a Scheudle file should really know from
  # what file it was derived.

  #
  DOMAIN = "rubyworks.github.com/detroit,2011-05-27"

  # TODO: If using Psych rather than Syck, then define a domain type.

  #if defined?(Psych) #RUBY_VERSION >= '1.9'
  #  YAML::add_domain_type(DOMAIN, "assembly") do |type, hash|
  #    Assembly.load(hash)
  #  end
  #else
    YAML::add_builtin_type("assembly") do |type, value|
      value
      #case value
      #when String
      #  Assembly.eval(value)
      #when Hash
      #  Assembly.new(value)
      #else
      #  raise "ERROR: Invalid Assembly"
      #end
    end
  #end

end
