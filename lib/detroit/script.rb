module Detroit

  # Script handles tool configuration.
  #
  class Script

    # Load.
    #
    # TODO: just pass root instead of project.
    def self.load(input, project=nil)
      new(:file=>input,:project=>project)
    end

    # Hash table of tool configuration.
    attr :tools

    # Project instance.
    attr :project

    # Access to project metadata.
    #
    # FIXME: Use factory method with root.
    def project
      @project #||= Project.new
    end

  private

    # Initialize new Script instance.
    #
    def initialize(options={}, &block)
      @project   = options[:project]
      @evaluator = EvalContext.new(self)
      @tools     = {}

      if file = options[:file]
        @file = Pathname.new(file)
        file_eval(@file)
      end

      if block
        ruby_eval(&block)
      end
    end

    # Evaluate script given it's file name.
    #
    # @return [void]
    def file_eval(file)
      file = Pathname.new(file)
      case file.extname
      when '.rb'
        ruby_eval(file.read, file.to_s)
      when '.yml', '.yaml'
        yaml_eval(file.read)
      else
        text = file.read
        if /^---/ =~ text
          yaml_eval(text)
        else
          ruby_eval(text, file)
        end
      end
    end

    # Evaluate a YAML script.
    #
    # @return [void]
    def yaml_eval(text)
      data = YAML.load(erb(text))
      if imports = data.delete('import')
        Array(imports).each{ |f| import(f) }
      end
      @tools = data
    end

    # Evalute a Ruby script.
    #
    # @return [void]
    def ruby_eval(*args)
      @evaluator.instance_eval(*args)
    end

  public

    # Ecapsulate a set of tools within a specific track.
    #
    # @return [void]
    def track(name, &block)
      @_track = name
      instance_eval(&block)
      @_track = nil
    end

    # Configure a tool.
    #
    # @return [Hash] tool settings
    def tool(name, settings={}, &block)
      settings[:track] = @_track if @_track
      if block
        block_context = BlockContext.new(&block)
        settings.update(block_context.settings)
      end
      @tools[name.to_s] = settings.rekey(&:to_s)
    end

    # Define a custom tool. A custom tool has no tool class.
    # Instead, the configuration itself defines the procedure.
    #
    # @return [Hash] tool settings
    def custom(name, &block)
      context  = CustomContext.new(&block)
      settings = context.settings
      @tools[name.to_s] = settings.rekey(&:to_s)
    end

    # Import tool configuration from another file.
    #
    # @return [void]
    def import(file)
      file_eval(file)
    end

  private

    # Process Routine document via ERB.
    #
    # @return [String]
    def erb(text)
      context = ERBContext.new(project)
      ERB.new(text).result(context.__binding__)
    end

    ##
    # Clean context for eveluation Ruby-based scripts.
    #
    class EvalContext < BasicObject
      def initialize(context)
        @_context = context
      end
      
      def track(name, &block)
        @_context.track(name, &block)
      end

      def tool(name, settings={}, &block)
        @_context.tool(name, settings, &block)
      end

      def custom(name, &block)
        @_context.custom(name, &block)
      end

	    def import(file)
	      @_context.import(file)
	    end

	    # Capitalized tool names called as methods can also define a tool.
	    def method_missing(sym, *args, &block)
	      tool_class = sym.to_s
	      case tool_class
	      when /^[A-Z]/
	        if Hash === args.last
	          args.last[:tool] = tool_class
	        else
	          args << {:tool => tool_class}
	        end
	        case args.first
	        when ::String, ::Symbol
	          name = args.first
	        else
	          name = tool_class.to_s.downcase
	        end
	        tool(name, *args, &block)
	      else
	        super(sym, *args, &block)
	      end
	    end
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
      def initialize(&b)
        @settings = {}
        b.arity == 1 ? b.call(self) : instance_eval(&b)
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
          return super(symbol, value, *args) unless args.empty?
          if value
            @settings[name.to_s] = value
          else
            @settings[name.to_s]
          end
        end
      end
    end

    #
    class CustomContext
      #
      attr :settings
      #
      def initialize(&b)
        @settings = {}
        b.arity == 0 ? instance_eval(&b) : b.call(self)
      end
      #
      def method_missing(s,a=nil,*x,&b)
        case s.to_s
        when /=$/
          @settings[s.to_s.chomp('=').to_sym] = b ? b : a
        else
          return @settings[s] unless a
          @settings[s] = b ? b : a
        end
      end
      def respond_to?(s)
        @settings.key?(s.to_sym)
      end
    end

  end

  # NOTE: This is problematic, because an Assembly file should know from
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
