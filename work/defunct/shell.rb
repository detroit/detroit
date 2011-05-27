require 'ratch/shell'
#require 'plugin'

module Redline

  # Shell is a subclass of Ratch::Shell (see rubyworks/ratch project).
  # It extends the Ratch::Shell with commands generally associated with
  # working with Ruby projects and other Ruby-oriented shell activies.
  #
  # Wherever possible a command should call on the underlying tool
  # programmatically rather than shelling out.
  #
  # TODO: What about other Ratch utilities?
  class Shell < Ratch::Shell

    # load shell add-ons
    #::Plugin.find('redline/shell/*.rb') do |file|
    #  require(file)
    #end

    require 'redline/shell/email.rb'
  end

end

