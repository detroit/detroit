require 'path/shell'
#require 'plugin'

module Syckle

  # Shell is a subclass of Path::Shell (see rubyworks/path project).
  # It extends the Path::Shell with commands generally associated with
  # working with Ruby projects and other Ruby-oriented shell activies.
  #
  # Wherever possible a command should call on the underlying tool
  # programmatically rather than shelling out.
  #
  class Shell < ::Path::Shell

    # load shell add-ons
    #::Plugin.find('syckle/shell/*.rb') do |file|
    #  require(file)
    #end

    require 'syckle/shell/email.rb'
  end

end

