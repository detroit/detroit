module Promenade
  # Access to this project's metadata.
  def self.metadata
    @metadata ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/promenade.yml'))
    )
  end

  # Access to project metadata via constants.
  def self.const_missing(name)
    metadata[name.to_s.downcase] || super(name)
  end

  # TODO: Only here b/c of bug in Ruby 1.8.x
  #VERSION = "1.0.0"
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

# Redtools provides the standard services.
require 'redtools'

# And all the rest is Promenade, baby.
if RUBY_VERSION > '1.9'
  require_relative 'promenade/core_ext'
  require_relative 'promenade/config'
  require_relative 'promenade/service'
  require_relative 'promenade/circuit'
  require_relative 'promenade/standard_circuit'
  require_relative 'promenade/control'
  require_relative 'promenade/application'
  require_relative 'promenade/schedule'
else
  require 'promenade/core_ext'
  require 'promenade/config'
  require 'promenade/service'
  require 'promenade/circuit'
  require 'promenade/standard_circuit'
  require 'promenade/control'
  require 'promenade/application'
  require 'promenade/schedule'
end
