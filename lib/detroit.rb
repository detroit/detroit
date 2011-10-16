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

  # TODO: Only here b/c of bug in Ruby 1.8.x
  #VERSION = "0.1.0"
end

# Erb is used to to script YAML-based schedule files.
require 'erb'

# OptionParser is used for command line parsing.
require 'optparse'

# Yea like we don't all ride a YAML.
require 'yaml'

# The ANSI gem is used to colorize terminal output.
require 'ansi/terminal'
require 'ansi/code'

# The parallel gem is used to (optionally) to multitask services.
begin
  require 'parallel'
rescue LoadError
end

# POM is used to access project metadata.
require 'pom'

# And all the rest is Detroit, baby.
if RUBY_VERSION > '1.9'
  require_relative 'detroit/core_ext'
  require_relative 'detroit/config'
  require_relative 'detroit/service'
  require_relative 'detroit/tool'
  require_relative 'detroit/assembly_system'
  require_relative 'detroit/standard_assembly'
  require_relative 'detroit/control'
  require_relative 'detroit/application'
  require_relative 'detroit/assembly'
  require_relative 'detroit/custom'
else
  require 'detroit/core_ext'
  require 'detroit/config'
  require 'detroit/service'
  require 'detroit/tool'
  require 'detroit/assembly_system'
  require 'detroit/standard_assembly'
  require 'detroit/control'
  require 'detroit/application'
  require 'detroit/assembly'
  require 'detroit/custom'
end
