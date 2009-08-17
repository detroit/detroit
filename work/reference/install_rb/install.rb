module Reap

  # Install package to site_ruby.
  #
  # This script installs project to site_ruby location
  # using Ruby's defualt configuration settings.
  # If you want to change these, you can supply
  # configuration settings for 'prefix' and/or 'sitedir'.

  def install

    system_prefix = Config::CONFIG['prefix']
    system_libdir = Config::CONFIG['sitelibdir']

    config = configuration['install'] || {}

    prefix = config['prefix'] || system_prefix
    libdir = config['libdir']

    unless libdir
      if (prefix == system_prefix) then
        libdir = system_libdir
      else
        libdir = File.join(prefix, system_libdir[system_prefix.size..-1])
      end
    end

    # If a roll file is being used.

    if roll_file = File.glob('{,meta/}*.roll').first
      roll = Roll::Package.open
      lib_paths = roll.lib_paths
    else
      lib_paths = config['lib_path'] || ['lib']
    end

    # We need to copy them into site_ruby in the opposite order they
    # would be searched for by require.

    lib_paths.reverse!

    # Copy lib files to site_ruby location, in proper order!

    lib_paths.each do |loc|
      files = glob(File.join(loc, "**/*"))
      files = files.select{ |f| File.file?(f) }
      files.each do |file|
        dest = File.dirname(file)
        dest.sub!(loc, '')
        dest = File.join(libdir, dest)
        if noharm?
          puts "mkdir -p #{dest}" unless File.directory?(dest)
          puts "install -m 0444 #{file} #{dest}"
        else
          mkdir_p dest unless File.directory?(dest)
          install file, dest, :mode => 0444
        end
      end
    end

    # Copy bin files to site_ruby location.

    bin_files = glob("bin/*")
    bin_files = bin_files.select{ |f| File.file?(f) }
    bin_files.each do |file|
      dest = File.dirname(file)
      dest = File.join(prefix, dest)
      if noharm?
        puts "mkdir -p #{dest}" unless File.directory?(dest)
        puts "install -m 0555 #{file} #{dest}"
      else
        mkdir_p dest unless File.directory?(dest)
        install file, dest, :mode => 0555
      end
    end

  end

end
