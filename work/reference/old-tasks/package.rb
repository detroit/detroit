require 'reap/project/gem'
require 'facets/platform'
#require 'facets/kernel/silence'

module Reap

  class Project

    PACKAGE_STORE = 'pkg'

    # Returns the package storage directory (now constant 'pkg').

    def package_store
      PACKAGE_STORE
    end

    # Current platform.

    def current_platform
      Platform.local.to_s
    end

    # Remove packages.

    def clobber_packages(options=nil)
      options = configure_options(options, 'package')

      store = 'pkg'

      packages = glob(File.join(store, '*'))

      packages.each do |path|
        rm_r(path)
        puts "Removed #{path}" unless dryrun?
      end
    end

    # Prepare for packaging (clean, distclean, version stamp).
    #
    # TODO: When we add support for binary packages distclean
    #       should not be done for them.

    def prepare(options)
      @prepared ||= (
        clean
        make_distclean if compiles?
        stamp(options)
        true
      )
    end

    # General pack command.

    def package(options=nil)
      packopts = configure_options(options, 'package')

      formats = packopts['formats'] || ['gem', 'tgz']
      formats = [formats].flatten

      prepare(options)

      puts unless dryrun?

      formats.each do |format|
        send("package_#{format}", options)
        #puts unless dryrun?
      end
    end

    # Routes to #gem_package.

    def package_gem(options=nil)
      begin
        require 'rubygems/specification'
        Gem::manage_gems
      rescue LoadError
        #raise LoadError, "RubyGems is not installed?"
      end

      options = configure_options(options, 'package-gem', 'package')
      extension = '.gem'

      platform  = options.delete('platform') || 'none'

      platforms = []
      platforms << nil if platform != 'only'
      platforms << 'current' if platform != 'none'

      platforms.each do |pl|
        options['platform'] = pl
        fname, metadata = package_prepare_stage(extension, options)
        next unless fname # if already built
        stage = File.join(package_store, fname)
        if dryrun?
          status "gem build #{stage}"
        else
          file = nil
          cd(stage) do
            #status "vi #{metadata.name}.gemspec"
            builder = ::Gem::Builder.new(gemspec(metadata))
            status "gem build #{stage}"
            unless dryrun?
              file = builder.build
              file = File.expand_path(file)
            end
          end
          # transfer gem package to package store
          mkdir_p(package_store)
          destination = File.join(package_store, File.basename(file))
          mv(file, package_store) unless File.expand_path(file) == File.expand_path(destination)
          puts
        end
      end
    end

    # Create a Gem package.
    #
    # TODO: Should this use staging too, like zip/tgz?

    #def gem_package(options=nil)
    #end


    # Create a Tar'd Gzip package.

    def package_tgz(options=nil)
      options = configure_options(options, 'package-tgz', 'package')

      platform  = options.delete('platform') || 'none'
      extension = '.tgz'

      platforms = []
      platforms << nil if platform != 'only'
      platforms << current_platform if platform != 'none'

      platforms.each do |pl|
        options['platform'] = pl
        fname, metadata = package_prepare_stage(extension, options)
        next unless fname  # if already built
        if dryrun?
          status "tar -cxf #{fname}.tgz"
        else
          file = nil
          cd(package_store) do
            file = compress(:tgz, fname)
          end
          transfer(file, package_store)
          report_package_built(file)
        end
      end
    end

    # Create Zip package.

    def package_zip(options=nil)
      options = configure_options(options, 'package-zip', 'package')

      platform  = options.delete('platform') || 'none'
      extension = '.zip'

      platforms = []
      platforms << nil if platform != 'only'
      platforms << current_platform if platform != 'none'

      platforms.each do |pl|
        options['platform'] = pl
        fname, metadata = package_prepare_stage(extension, options)
        next unless fname  # if already built
        if dryrun?
          status "zip -r #{fname}.zip ."
        else
          file = nil
          cd(package_store) do
            file = compress(:zip, fname)
          end
          transfer(file, package_store)
          report_package_built(file)
        end
      end
    end

    # Create off-line documentation package.
    #
    # FIXME: package_docs is not yet ready for use.
    #
    #def package_docs(options=nil)
    #  options = configure_options(options, 'package-doc')
    #
    #  dir  = options['dir']     || 'doc'
    #  name = options['name']    || metadata.name
    #  ver  = options['version'] || metadata.version
    #
    #  cd(dir) do
    #    zip "-czhvf #{name}-docs-#{ver}.zip *"
    #  end
    #end

    private

    #

    def package_prepare_stage(extension, options)
      prepare(options)

      metadata = metadata().clone
      metadata.update(options)

      abort "No name"     unless metadata.name
      abort "No version"  unless metadata.version

      fname = metadata.stage_name

      if compiles?
        streams = verbose? ? [] : [STDOUT, STDERR]
        silence_stream(*streams) do
          make_distclean
          # If platform package then pre-compile
          if options['platform']
            make
          end
        end
      end

      stage = File.join(package_store, fname)

      pfile = stage + extension #".tgz"

      files = metadata.filelist

      unless out_of_date?(pfile, *files) or force?
        report_package_already_built(pfile)
        return nil, metadata
      end

      rm_r(stage) if File.exist?(stage)  # remove old stage

      stage(stage, files)                # make new stage

      package_manifest(stage)            # generate stage manifest

      return fname, metadata
    end

    # Transfer package file to storage location.

    def transfer(file, store)
      # move to store, unless already there
      dest = File.join(store, File.basename(file))
      dest = File.expand_path(dest)
      mv(file, store) unless file == dest
    end

    # Generate manifest.

    def package_manifest(dir)
      return if dryrun?
      Dir.chdir(dir) do
        files = Dir['**/*']
        rm('MANIFEST') if File.exist?('MANIFEST')
        File.open('MANIFEST', 'w') do |f|
          f << files.join("\n")
        end
      end
    end

    # Report that a package has been built.
    # FIXME: will type, name and version always be right?

    def report_package_built(file)
      file = File.basename(file)
      type = File.extname(file)
      name = file[0...file.rindex('-')]
      vers = file[file.rindex('-')+1..-1].chomp(type)

      puts "  Successfully built #{type}"
      puts "  Name: #{name}"
      puts "  Version: #{vers}"
      puts "  File: #{file}"
      puts
    end

    # Report that a package has been built.
    # FIXME: will type, name and version always be right?

    def report_package_already_built(file)
      file = File.basename(file)
      type = File.extname(file)
      name = file[0...file.rindex('-')]
      vers = file[file.rindex('-')+1..-1].chomp(type)

      puts "  Package #{file} is already current."
      puts
      #puts "  Name: #{name}"
      #puts "  Version: #{vers}"
      #puts "  File: #{file}"
    end

  end
end

  #     # Build packages.
  #     # TODO Move this to Manager ?
  #
  #     def generate_packages
  #       package_files = formats.collect do |format|
  #         #format = clean_type(format)
  #         say '' if format == 'gem'  # FIXME This is here b/c Gems outputs on it's own.
  #         file = create_package(format)
  #         unless dryrun? or (format == 'gem')
  #           report_package_built(format, file) if file
  #         end
  #         file
  #       end
  #       report_packaging_complete(package_files.size)
  #     end
  #
  #     # Create package.
  #
  #     def create_package(type)
  #       package.format = type
  #
  #       builder_class = FormatBuilder.registry[type]
  #       builder = builder_class.new(package, stage_directory, options)
  #       file    = builder.build
  #
  #       transfer(file) unless dryrun?
  #
  #       return file
  #     end
  #
  #     # Report that packaging is complete.
  #
  #     def report_packaging_complete(size)
  #       say "\nSuccessfully built #{size} packages at #{store}/."
  #     end


=begin
      prepare(options)

      package = metadata.clone
      package.update(options)

      abort "No name" unless package.name
      abort "No version" unless package.version

      fname = package.stage_name
      files = package.filelist

      stage = File.join(package_store, fname)
      pfile = stage + ".zip"

      unless out_of_date?(pfile, *files) or force?
        report_package_already_built(pfile)
        return
      end 

      rm_r(stage) if File.exist?(stage)  # remove old stage
      stage(stage, files)                # make new stage
      package_manifest(stage)            # generate manifest

      if dryrun?
        status "zip -r #{fname}.zip ."
      else
        file = nil
        cd(package_store) do
          file = zip(fname)
        end
        transfer(file, package_store)
        report_package_built(file)
      end
=end

=begin
      prepare(options)

      package = metadata.clone
      package.update(options)

      abort "No name" unless package.name
      abort "No version" unless package.version

      store = 'pkg' #package.package_directory
      fname = package.stage_name
      files = package.filelist

      stage = File.join(store, fname)

      pfile = stage + ".tgz"

      unless out_of_date?(pfile, *files) or force?
        report_package_already_built(pfile)
        return
      end

      rm_r(stage) if File.exist?(stage)  # remove old stage
      stage(stage, files)                # make new stage

      package_manifest(stage)            # generate stage manifest
=end

