module Pitstop
  # Access to project metadata.
  def self.metadata
    @metadata ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/pitstop.yml'))
    )
  end

  # Access to project metadata via constants.
  def self.const_missing(name)
    metadata[name.to_s.downcase] || super(name)
  end

  # TODO: Only here b/c of bug in Ruby 1.8.x
  #VERSION = "1.0.0"
end

# Erb is used to to script YAML-based pitfiles.
require 'erb'

# OPtionParser is used for command line parsing.
require 'optparse'

# Yea like we don't all ride a YAML.
require 'yaml'

# The ANSI gem is used to colorize terminal output.
require 'ansi/terminal'
require 'ansi/code'

# The parallel gem is used to (optionally) multitask services.
begin
  require 'parallel'
rescue LoadError
end

# POM is used to access project metadata.
require 'pom'

# Redtools provide the standard services.
require 'redtools'

# And all the rest is Pitstop, baby.
require 'pitstop/core_ext'
require 'pitstop/config'
require 'pitstop/service'
require 'pitstop/circuit'
require 'pitstop/standard_circuit'
require 'pitstop/control'
require 'pitstop/application'
require 'pitstop/pitfile'

