# TODO: Perhaps generalize plugin lookup and move it to POM, or Roll?

require 'reap/plugin'

module Reap

  def self.plugins
    @plugins ||= (
       h = {}
       plugin_directories.each do |dir|
         h[File.basename(dir).chomp('.reap')] = dir
       end
       h
    )
  end

  # This routine searches through the $LOAD_PATH
  # looking for directories which end in '.reap'.
  #
  def self.plugin_directories
    paths = []

    # standard load path
    $LOAD_PATH.uniq.each do |path|
      dirs = Dir.glob(File.join(path, '**', '*.reap/'))
      #dirs = dirs.select{ |d| File.directory?(d) }
      paths.concat(dirs)
    end

    # rolls
    if defined?(::Roll)
      ::Roll::Library.ledger.each do |name, lib|
        lib = lib.sort.first if Array===lib
        lib.load_path.each do |path|
          path = File.join(lib.location, path)
          dirs = Dir.glob(File.join(path, '**', '*.reap/'))
          #dirs = dirs.select{ |d| File.directory?(d) }
          paths.concat(dirs)
        end
      end
    end

    #if defined?(::Gem)
    #  Gem.find_files('*.sow').reverse_each do |path|
    #    if File.directory?(path)
    #      paths << path
    #    end
    #  end
    #end

    return paths.map{ |d| d.chomp('/') }
  end

  # TODO: Open this up to all plugins

  # STANDARD_PLUGINS = %w{
  #   autotools box devnotes flog mailinglist rcov relnotes
  #   respect rspec sowgen syntax testunit turn
  #   txt2man vclog svn hg git
  # }

  STANDARD_PLUGINS = %w{
    box stats custom notes email rcov rdoc ridoc rubyforge rubyprof testrb turn webri yard
  }

  STANDARD_PLUGINS.each do |name|
    #require "reap/plugins/#{plugin}/plugin"
    require plugins[name] + '/plugin' if plugins[name]
  end

end
