module Detroit

  module Toolchain

    # Assembly::Script models an *Assembly file* with it's collection of 
    # tool configurations.
    #
    class Script

      # Load Assembly file.
      def self.load(input, project=nil)
        new(:file=>input,:project=>project)
      end

      # Project instance.
      attr :project

      # Hash table of tool configuration.
      attr :tools

    private

      #
      def initialize(options={}, &block)
        @project = options[:project]

        @tools = {}

        if options[:file]
          initialize_file(options[:file])
        end

        if block
          instance_eval(&block)
        end
      end

      # Inititalize from assembly file.
      #
      def initialize_file(file)
        @file = (String === file ? File.new(file) : file)

        case File.extname(@file.path)
        when '.rb'
          instance_eval(@file.read, @file.path)
        when '.yml', '.yaml'
          @tools = YAML.load(erb(@file.read))
        else
          text = @file.read
          if /^---/ =~ text
            @tools = YAML.load(erb(text))
          else
            instance_eval(text, @file.path)
          end
        end
      end

    public

      # Ecapsulate a set of tools within a specific track.
      #  
      def track(name, &block)
        @_track = name
        instance_eval(&block)
        @_track = nil
      end

      # Configure a tool.
      #
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
      def custom(name, &block)
        context  = CustomContext.new(&block)
        settings = context.settings
        @tools[name.to_s] = settings.rekey(&:to_s)
      end

      # Access to project metadata.
      #
      # FIXME: Use factory method
      def project
        @project ||= Project.new
      end

    private

      # Capitalized tool names called as methods
      # can also define a tool.
      def method_missing(sym, *args, &block)
        tool_class = sym.to_s
        case tool_class
        when /^[A-Z]/
          if Hash === args.last
            args.last[:tool] = tool_class
          else
            args << {:tool=>tool_class}
          end
          case args.first
          when String, Symbol
            name = args.first
          else
            name = tool_class.to_s.downcase
          end
          tool(name, *args, &block)
        else
          super(sym, *args, &block)
        end
      end

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

end
