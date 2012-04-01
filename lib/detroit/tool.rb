module Detroit

  # TODO: The plan is to replace most, if not all, of the fileutils
  #       functionality with Ratch when it is ready.

  require 'detroit/tool/core_ext'
  require 'detroit/tool/shell_utils'
  require 'detroit/tool/project_utils'
  require 'detroit/tool/email_utils'

  # The Tools module provides an isolated namespace for
  # Detoit's tools. This allows for general use of these
  # tools by other applications, by including them into
  # their own namespace.
  #
  module Tools
    #BasicTool = Detroit::BasicTool
    #Tool      = Detroit::Tool
  end

  #
  # Tool registry.
  #
  def self.tools
    @tools ||= {}
  end

  #
  # Alias for #tools.
  # 
  def self.services
    tools
  end

  #
  #
  #
  def self.define_tool_method(name, tool_class)
    (class << self; self; end).class_eval do
      # raise if method_defined?(name)
      define_method(name) do |*a, &b|
        tool_class.new(*a,&b)
      end
    end
  end

  #
  # Add tool class to registry. If class name ends in `Base`
  # it will be considered a reusable base class and not be added.
  #
  def self.register_tool(tool_class)
    name = tool_class.basename
    return if name.empty?
    return if name == 'Tool'
    return if name =~ /Base$/
    tools[name.downcase] = tool_class
    Tools.const_set(name, tool_class)
    Detroit.define_tool_method(name, tool_class)
    return tool_class
  end

  # This base class can be used for tools that do not need
  # all of the utility methods provided by the regular Tool
  # class.
  #
  class BasicTool
    class << self
      # Add an assembly system to which the tool applies.
      # By default the `standard` system is implied.
      def assembly_system(assembly=nil)
        @assembly ||= []
        if assembly
          @assembly << assembly.to_sym
          @assembly.uniq!
        end
        @assembly
      end

      # Shorter alias for #assembly_system.
      alias_method :assembly, :assembly_system

      # Override the `tracks` method to limit the lines a service
      # will work with by default. Generally this is not used,
      # and a return value of +nil+ means all lines apply.
      #
      # @todo Rename to #lines ?
      #
      def tracks
      end

      # Override this method if the tools availability is conditional.
      def available?
        true
      end

      # Returns list of writer method names. This is used for reference.
      def options(service_class=self)
        i = service_class.ancestors.index(Tool) ||
            service_class.ancestors.index(BasicTool)
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

      # Returns a Class which is a new subclass of the current class.
      def factory(&block)
        Class.new(self, &block)
      end

      # When inherited, add class to tool registry.
      def inherited(base)
        Detroit.register_tool(base)
      end
    end

    #
    # @todo Is this neeeed? Maybe rename?
    #
    def service_title
      self.class.name
    end

    #
    # Override this method so the assembly system can determine if the
    # station is applicable with the given state of the project. By default
    # the return value is always `true`.
    #
    # @param [Symbol] station
    #
    # @param [Hash] options
    #   Additonal information significant to the determination.
    #
    # @option options [Symbol] :destination
    #   The final stop designated for the particular run.
    #
    # @return [Boolean] Is the particular station applicable?
    #
    def assemble?(station, options={})
      warn "tool #{self.class} has not defined an #assemble? method"
      false
    end

    #
    # Use the tool for the given station. By default this method does nothing
    # It must be overriden by the tool to direct execution for the given station.
    #
    # @param [Symbol] station
    #
    # @param [Hash] options
    #   Additonal information significant to the determination.
    #
    # @option options [Symbol] :destination
    #   The final stop designated for the particular run.
    #
    def assemble(station, options={})
      warn "tool #{self.class} has not defined an #assemble method"
    end
  end

  # Tool is the base class for all Detroit tools.
  #
  # Tool class is essentially the same as the {BasicTool} but provides an
  # assortment of addtional data and utility methods often useful to tools.
  # Use this class to build Detroit tools with all the conveniences.
  #
  class Tool < BasicTool
    include ShellUtils
    include ProjectUtils
    include EmailUtils

    public

    #
    attr :options

    # If applicable tools should override #current to allow tool users
    # to know if the tool needs to be used. For example the RDoc tool
    # can look to see if any the files it would document are newer that
    # the previous generated set of docs.
    #
    # The method can return a String instead of `true`, to convey a
    # custom message explaining that the tool need not be run. For example,
    # the RDoc tool returns "RDocs are current (path/to/rdocs)". 
    def current?
      false
    end

    private

    # Create a new tool object.
    #
    # This sets up utility extensions and assigns options to setter attributes
    # if they exist and values are not nil. That last point is important.
    # You must use 'false' to purposely negate an option, as +nil+ will instead
    # allow any default setting to be used.
    #
    def initialize(options={})
      initialize_extension_defaults

      initialize_requires
      initialize_defaults

      initialize_options(options)

      initialize_extensions
    end

    # TODO: It would be best if an error were raised if an option is not
    # supported, however for now only a warning will be issued, b/c
    # subclassing makes things more complicated.
    def initialize_options(options)
      @options = options

      options.each do |k, v|
        #send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
        if respond_to?("#{k}=")
          send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
        else
          warn "#{self.class.name} does not respond to `#{k}`."
        end
      end
    end

    #
    def initialize_extension_defaults
      super if defined?(super) 
    end

    # Require support libraries needed by this service.
    #
    #   def initialize_requires
    #     require 'ostruct'
    #   end
    #
    def initialize_requires
    end

    # When subclassing, put default instance variable settngs here.
    #
    # Examples
    #
    #   def initialize_defaults
    #     @gravy = true
    #   end
    #
    def initialize_defaults
    end

    # --- Odd Utilities -------------------------------------------------------

    require 'facets/platform'

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    # TODO: How to set naming policy in a more universal manner?

    #
    #
    def naming_policy(*policies)
      if policies.empty?
        @naming_policy ||= ['down', 'ext']
      else
        @naming_policy = policies
      end
    end

    #
    #
    def apply_naming_policy(name, ext)
      naming_policy.each do |policy|
        case policy.to_s
        when /^low/, /^down/
          name = name.downcase
        when /^up/
          name = name.upcase
        when /^cap/
          name = name.capitalize
        when /^ext/
          name = name + ".#{ext}"
        end
      end
      name
    end

  end
end
