module Detroit

  require 'detroit/tool/core_ext'
  require 'detroit/tool/shell_utils'
  require 'detroit/tool/project_utils'
  require 'detroit/tool/email_utils'

  # The Toold module provide an isolated namespace for
  # Detoit's tools. This allows for general use of these
  # tools by other applications, by including them into
  # their own namespace.
  module Tools
  end

  # Tool registry.
  def self.tools
    @tools ||= {}
  end

  # 
  def self.services
    tools
  end

  # Add tool class to registry. If class name ends in `Tool`
  # it will be considered a reusable base class and not be added.
  def self.register_tool(tool_class)
    name = tool_class.basename
    return if name.empty?
    return if name =~ /(Tool|Service)$/
    tools[name.downcase] = tool_class
    Tools.const_set(name, tool_class)
    # TODO: Should we auto-create convenience method?
    return tool_class
  end

  # This base class can be used for tools that do not need
  # all of the utility methods provided by the regular Tool
  # class.
  class BasicTool
    # Add an assembly to which the tool applies.
    # By default the `standard` assembly is implied.
    def self.assembly(assembly=nil)
      @assembly ||= []
      if assembly
        @assembly << assembly.to_sym
        @assembly.uniq!
      end
      @assembly
    end

    # Override the `tracks` method to limit the lines a service
    # will work with by default. Generally this is not used,
    # and a return value of +nil+ means all lines apply.
    #--
    # TODO: Rename to #lines ?
    #++
    def self.tracks
    end

    # Override this method if the tools availability is conditional.
    def self.available?
      true
    end

    # Returns list of writer method names.
    def self.options(service_class=self)
      service_class.instance_methods.
        select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }.
        map{ |m| m.to_s.chomp('=') }
    end

    # Returns a Class which is a new subclass of the current class.
    def self.factory(&block)
      Class.new(self, &block)
    end

    # When inherited, add class to tool registry.
    def self.inherited(base)
      Detroit.register_tool(base)
    end

    # TODO: Needed? Rename?
    def service_title
      self.class.name
    end
  end

  # Tool is the base class for all Detroit tools.
  #
  # Tool class is essentially the same as a Service class except that it is
  # a subclass of RedTools::Tool. Use this class to build Detroit services
  # with all the conveniences of a RedTools::Tool.
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
    # supported, however for now only a warning will be issued, b/c of 
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

    # TODO: Is naming_policy really useful?
    # TODO: How to set this in a more universal manner?
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
