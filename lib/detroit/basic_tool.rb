module Detroit

  ##
  # This base class can be used for tools that do not need
  # all of the utility methods provided by the regular Tool
  # class.
  #
  class BasicTool
    include BasicUtils

    # Call this method to register the tool with a tool chain.
    # The provided block determines how the the tool is used
    # in the toolchain.
    #
    # How to use the tool for a given station. Thie method must either return
    # then name of a method to call, or a procedure to call. By default it simply
    # returns the name of the station if a the tool repsonds to a method of the
    # same name. If the tool does not handle the station it must return nil or
    # false.
    #
    # @param [ToolChain] tool_chain
    #
    # @example
    #   class Foo < Tool
    #     toolchain Standard,
    #       :document => :save
    #     ...
    #
    # @return [Hash] Map of toolchain to assembly procedure.
    def self.toolchain(tool_chain=nil, *stages)
      @toolchain ||= {}

      if tool_chain
        map = stages.inject({}) do |h, s|
          Hash === s ? h.update(s) : h[s] = s; h
        end
        @toolchain[tool_chain] = map  

        Detroit.register_tool(self)

        include(tool_chain)
      else
        @toolchain
      end
    end

    # @yieldparam [Hash] options
    #   Additonal information significant to the procedure.
    #   The only option at this time it `:stop` which is the
    #   name of the final destination for the current run.
    #

    # Returns a Class which is a new subclass of the current class.
    #def self.factory(&block)
    #  Class.new(self, &block)
    #end

    # Override the usual new method in order to apply prerequisites.
    #
    # @return [BasicTool]
    def self.new(options={})
      tool = allocate
      ancestors.reverse_each do |anc|
        if pre = anc.instance_method(:prequisite) rescue nil
          pre.bind(tool).call
        end
      end
      tool.initialize(options)
      tool
    end

    # Returns list of writer method names. This is used for reference.
    #
    # @return [Array<String>]
    def self.options(service_class=self)
      i = service_class.ancestors.index(Tool)
      m = []
      service_class.ancestors[0..i].each do |sc|
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
          warn "#{self.class.name} does not respond to `#{k}`."
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

  end

end
