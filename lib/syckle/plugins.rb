#require 'syckle/plugin'

module Syckle

  #
  PLUGIN_DIRECTORY = "syckles"

  # This routine searches through the $LOAD_PATH
  # looking for plugins matching 'scythes/*.rb'.
  #
  def self.plugins
    @plugins ||= (
      f = []

      # LOAD_PATH
      $LOAD_PATH.uniq.map do |path|
        dirs = Dir.glob(File.join(path, PLUGIN_DIRECTORY, '*.rb'))
        f.concat(dirs)
      end

      # ROLL
      if defined?(::Roll)
        ::Roll::Library.ledger.each do |name, lib|
          lib = lib.sort.first if Array===lib
          lib.load_path.each do |path|
            path = File.join(lib.location, path)
            dirs = Dir.glob(File.join(path, PLUGIN_DIRECTORY, '*.rb'))
            f.concat(dirs)
          end
        end
      end

      # TODO: RubyGems
      #if defined?(::Gem)
      #  Gem.find_files('*.sow').reverse_each do |path|
      #    if File.directory?(path)
      #      paths << path
      #    end
      #  end
      #end

      f
    )
  end

  # TODO: Open this up to all plugins

  # STANDARD_PLUGINS = %w{
  #   autotools box devnotes flog mailinglist rcov relnotes
  #   respect rspec sowgen syntax testunit turn
  #   txt2man vclog svn hg git
  # }

  #STANDARD_PLUGINS = %w{
  #  box stats custom notes email rcov rdoc ridoc rubyforge rubyprof testrb turn webri yard
  #}

  #STANDARD_PLUGINS.each do |name|
  #  #require "syckle/plugins/#{plugin}/plugin"
  #  require plugins[name] + '/plugin' if plugins[name]
  #end

end
