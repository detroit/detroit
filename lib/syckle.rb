require 'yaml'

module Syckle
  DIRECTORY = File.dirname(__FILE__) + '/syckle'

  PROFILE = YAML.load(File.new(DIRECTORY + '/profile.yml'))
  VERFILE = YAML.load(File.new(DIRECTORY + '/version.yml'))

  VERSION = VERFILE.values_at(*%w{major minor patch build}).join('.')

  #
  def self.const_missing(name)
    key = name.to_s.downcase
    VERFILE[key] || PROFILE[key] || super(name)
  end
end

