module Detroit
  # Access to this project's metadata.
  def self.metadata
    @metadata ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/detroit.yml'))
    )
  end

  # Access to project metadata via constants.
  def self.const_missing(name)
    metadata[name.to_s.downcase] || super(name)
  end
end

require 'pathname'
require 'erb'           # Erb is used to to script YAML-based schedule files.
require 'optparse'      # OptionParser is used for command line parsing.
require 'yaml'          # Yea like we don't all ride a YAML.

require 'indexer'       # Indexer is used to provide project metadata.
require 'ansi/terminal' # The ANSI gem is used to colorize terminal output.
require 'ansi/code'

# The optional parallel gem is used to multitask services.
begin
  require 'parallel'
rescue LoadError
end

require_relative 'detroit/core_ext'
require_relative 'detroit/project'
require_relative 'detroit/runner'
require_relative 'detroit/cli'
require_relative 'detroit/script'
require_relative 'detroit/worker'
require_relative 'detroit/exec'

require_relative 'detroit/basic_utils'
require_relative 'detroit/shell_utils'
require_relative 'detroit/email_utils'
require_relative 'detroit/ruby_utils'

require_relative 'detroit/basic_tool'


module Detroit

  #
  # Tool registry.
  #
  def self.tools
    @tools ||= {}
  end

  #
  # Define tool method.
  #
  def self.define_tool_method(name, tool_class)
    (class << self; self; end).class_eval do
      # raise or skip if method_defined?(name)
      define_method(name) do |*a, &b|
        tool_class.new(*a, &b)
      end
    end
  end

  #
  # Add tool class to registry. If class name ends in `Tool` or `Base`
  # it will be considered a reusable base class and not be added.
  #
  def self.register_tool(tool_class)
    name = tool_class.basename
    # four good reasons not to ignore
    return if name.nil?
    return if name.empty?
    return if name =~ /Tool$/
    return if name =~ /Base$/
    # add tool to lookup table
    tools[name.downcase] = tool_class
    # add tool to Tools module
    Tools.const_set(name, tool_class)
    # define convenience method in Detroit namespace
    Detroit.define_tool_method(name, tool_class)
    # return the class
    return tool_class
  end

=begin
  ##
  # Per-project configuration for detroit.
  #
  # TODO: Do we really need this?
  class Config < BasicObject
    FILE = ".detroit"

    def initialize(root)
      @file = Dir.glob(root + FILE).first

      if @file
        @data = YAML.load_file(@file)
      else
        @data = {}
      end
    end

    def method_missing(s, *a, &b)
      @data[s.to_s]
    end
  end
=end

  ##
  # The Tools module provides an isolated namespace for Detoit's tools.
  # This allows for general use of these tools by other applications,
  # simply by including the Detroit::Tools module into their own namespace.
  #
  module Tools
  end

  ##
  # The common base class for tools. Tool is a subclass of BasicTool that
  # adds additional utility methods, in particular it adds {ShellUtils}.
  # Unless there is a specific reason not to do so, this is the class 
  # that specific tool classes should subclass.
  #
  # A good tool will check to see if the state of the project is *current*
  # or not to know if some stage of the tool needs to be used or not.
  # For example a documentation# tool can look to see if any the files
  # it would document are newer that the previous generated set of document
  # file. In this case it can output a message explaining that the action
  # was not needed. For example, the RDoc tool outputs the message:
  # "RDocs are current (path/to/rdocs)". The tool can also support the 
  # `$FORCE` global to force the procedure regardless.
  #
  class Tool < BasicTool
    include ShellUtils
  end

end

require_relative 'detroit/assembly'
#require_relative 'detroit/standard'

