module Detroit

  module Assembly

    # Assembly::Script models an *Assembly file* with it's collection of 
    # tool configurations.
    #
    class Script

      # Load Assembly file.
      def self.load(input, project=nil)
        new(:file=>input,:project=>project)
      end

      #
      attr :project

      # Hash table of services definitions.
      attr :services

    private

      #
      def initialize(options={}, &block)
        @project = options[:project]

        @services = {}

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

    public

      #  
      def track(name, &block)
        @_track = name
        instance_eval(&block)
        @_track = nil
      end

      # Define a service.
      def service(name, settings={}, &block)
        settings[:track] = @_track if @_track
        if block
          block_context = BlockContext.new(&block)
          settings.update(block_context.settings)
        end
        @services[name.to_s] = settings.rekey(&:to_s)
      end

      alias_method :tool, :service

      #
      #
      #
      #
      def custom(name, &block)
        context  = CustomContext.new(&block)
        settings = context.settings
        @services[name.to_s] = settings.rekey(&:to_s)
      end

      # Access to project metadata.
      def project
        @project ||= Project.new
      end

    private

      # Capitalized service names called as methods
      # can also define a service.
      def method_missing(sym, *args, &block)
        service_class = sym.to_s
        case service_class
        when /^[A-Z]/
          if Hash === args.last
            args.last[:service] = service_class
          else
            args << {:service=>service_class}
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
