module Detroit

  ##
  # This base class can be used for tools that do not need
  # all of the utility methods provided by the regular Tool
  # class.
  #
  class BasicTool
    include BasicUtils

    # Call this method to register a tool with an assembly.
    # A tool can only belong to one assembly, but migration
    # adapters can be defined to allow tools from one assembly
    # to work with another (COMING SOON).
    #
    # @param [Assembly] a (optional)
    #   Assembly for which this tool is designed.
    #
    # @example
    #   class SomeTool < Tool
    #     assembly Standard
    #
    # @return [Assembly] Assembly module.
    def self.assembly(a=nil)
      #include(@assembly = a) if a
      include(a) if a
      @assembly
    end

    #
    def self.assembly=(a)
      @assembly = a
    end

    ## Specify a supported station. This is used by the `chain?` method to
    ## determine if station is supporte by a tool. This is more convenient
    ## then overridding `chain?` method.
    #def self.station(name, alt=nil)
    #  define_method("station_#{name}") do |options={}|
		#    meth = method(alt || name)
		#    case meth.arity
		#    when 0
		#      meth.call()
		#    else
		#      meth.call(options)
		#    end
    #  end
    #end

    # Returns a Class which is a new subclass of the current class.
    #def self.factory(&block)
    #  Class.new(self, &block)
    #end

    # Override the usual new method in order to apply prerequisites.
    #
    # @return [BasicTool]
    def self.new(options={})
      tool = allocate
      # set root before running prereqs
      tool.root = options['root']
      # run prerequsites
      ancestors.reverse_each do |anc|
        next if (anc == BasicObject || anc == Object || anc == Kernel)
        if anc.instance_methods.include?(:prerequisite)
          pre = anc.instance_method(:prerequisite)
          pre.bind(tool).call
        end
      end
      # now initialize
      tool.send(:initialize, options)
      # return tool instance
      tool
    end

    # Returns list of writer method names. This is used for reference.
    #
    # @return [Array<String>]
    def self.options(tool_class=self)
      i = tool_class.ancestors.index(Tool)
      m = []
      tool_class.ancestors[0..i].each do |sc|
        sc.public_instance_methods(false).each do |pm|
          next if pm !~ /\w+=$/
          next if %w{taguri=}.include?(m.to_s)
          m << pm.to_s.chomp('=')
        end
      end
      m
    end

    # Override this method if the tool's availability is conditional.
    #
    # @return [Boolean]
    def self.available?
      true
    end

    # This pre-initialization procedure is run before #initialize and
    # for all ancestors, so `#super` should never be called within it.
    # The method is intended to be used to require dependencies for a tool,
    # so that tool's dependencies are only required when needed. But it can
    # also be used to set pre-option attribute defaults.
    #
    # @example
    #   def prerequisite
    #     require 'ostruct'
    #     @gravy = true
    #   end
    #
    # @return [void]
    def prerequisite
    end

    # Create a new tool object.
    #
    # This sets up utility extensions and assigns options to setter attributes
    # if they exist and values are not nil. That last point is important.
    # You must use 'false' to purposely negate an option, as +nil+ will instead
    # allow any default setting to be used.
    #
    # @return [void]
    def initialize(options={})
      initialize_options(@options = options)
    end

    # Called by `#initialize` to call writers from given options.
    #
    # @return [void]
    def initialize_options(options)
      options.each do |k, v|
        #send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
        if respond_to?("#{k}=")
          send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
        else
          warn "#{self.class.name} does not respond to `#{k}=`."
        end
      end
    end

    # Access to all options passed into `#initialize`.
    #
    # @return [Hash]
    attr :options

    #
    # @todo Is this needed?
    #
    def title
      self.class.name
    end

    # Does this tool attach to the specified station?
    #
    # By default this checks for the definition of a public method in the tool
    # class with the same name as the station. Note, it does not use `respond_to?`
    # to do this, which would find any such method in the class hierarchy. Instead
    # it specifically checks for a definition in the tool class itself. This
    # helps prevent potential accidental name clashes between support methods
    # and station names.
    #
    def assemble?(station, options={})
      self.class.public_methods(false).include?(station.to_sym)
    end

    #
    def assemble(station, options={})
      meth = method(station)

      case meth.arity
      when 0
        meth.call()
      else
        meth.call(options)
      end
    end

    # Project instance.
    def project
      @project ||= Project.factory(root || Dir.pwd)
    end

    # Shortcut to project metadata.
    def metadata
      project.metadata
    end

    # Project root directory.
    #
    # @return [Pathname]
    def root
      @root
    end

    def root=(dir)
      @root = dir
    end

  end

end
