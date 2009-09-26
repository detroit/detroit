module Syckle

  #
  PLUGIN_DIRECTORY = "syckles"

  # This routine searches through the $LOAD_PATH
  # looking for plugins matching 'scythes/*.rb'.
  #
  def self.plugins
    @plugins ||= (
      plugins = []
      # Standard LOAD_PATH
      $LOAD_PATH.uniq.map do |path|
        files = Dir.glob(File.join(path, PLUGIN_DIRECTORY, '*.rb'))
        plugins.concat(files)
      end
      # ROLL (load latest versions only)
      if defined?(::Roll)
        ::Roll::Library.ledger.each do |name, lib|
          lib = lib.sort.first if Array===lib
          lib.load_path.each do |path|
            path = File.join(lib.location, path)
            files = Dir.glob(File.join(path, PLUGIN_DIRECTORY, '*.rb'))
            plugins.concat(files)
          end
        end
      end
      # RubyGems (load latest versions only)
      if defined?(::Gem)
        Gem.latest_load_paths do |path|
          files = Dir.glob(File.join(path, PLUGIN_DIRECTORY, '*.rb'))
          plugins.concat(files)
        end
      end
      plugins.uniq
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
