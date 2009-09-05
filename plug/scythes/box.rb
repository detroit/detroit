
# FUTURE ?
#service :box do
#
#  init do |options|
#    require 'ratchets/box'
#    @box = Ratchets::Box(options)
#  end
#
#  cycle 'main:configure' do
#    # ...
#  end
#
#  cycle 'main:package' do
#    @box.package
#  end
#
#end


module Syckles

  # = Box Packaging Service
  #
  # The Box plugin, as the name suggests, utilizes the
  # stand-alone +box+ tool to build packages.
  #
  class Box < Service

    cycle :main, :package

    # Default package types passed to the +box+ command.
    DEFAULT_TYPES = ['tar']

    # Default patterns of files to include in a manifest file.
    DEFAULT_INCLUDE = ['**/*']

    # Directories that a typically excluded from a distribution.
    DEFAULT_EXCLUDE = %w{ .cache .config log pack pkg temp temps tmp tmps web site website work }

    # File pattern are files/dirs that are typically ignored.
    DEFAULT_IGNORE  = %w{ .* }

    # Package types to produce.
    attr_accessor :types

    # In case only a single package type is needed.
    alias_accessor :type, :types

    # Manifest file to use. Default is +MANIFEST+ case-insensitve
    # with optional +.txt+ extension.
    attr_accessor :manifest

    # Regenerate manifest (true or false)? The default is +false+.
    # Unless this is set to +true+ a MANIFEST file must already
    # be present in the project's root directory.
    #
    # It is generally considered good practice to manually
    # manitain a MANIFEST file. However, if a project has complex
    # packaging needs, such as special manifests per specific
    # package types, then auto-generating the MANIFEST file
    # proves invaluable.
    attr_accessor :remanifest

    # Convenient alias for #remanifest.
    alias_method :remanifest?, :remanifest

    # Globs of files and/or directories to include in manifest.
    # This is not used unless remanifest is set to true.
    attr_accessor :distribute

    # Alias for #distribute.
    alias_accessor :include, :distribute

    # Globs of files and/or directories to exclude from manifest.
    # This is not used unless remanifest is set to true.
    attr_accessor :exclude

    # Standard files to ignore. Defaults to hidden files (.*).
    # Unlike exclude these match against the basename, rather
    # than the full pathname.
    # This is not used unless remanifest is set to true.
    attr_accessor :ignore

    # Save spec file (if applicable)
    attr_accessor :spec

    # Set package types to produce.
    # This is a special writer to allow for a single glob or a list of globs.
    def types=(val)
      @types = [val].flatten
    end

    # Set file patterns used to select files to distribute in package.
    # This is a special writer to allow for a single glob or a list of globs.
    def distribute=(val)
      @distribute = [val].flatten
    end

    # Set file patterns to exclude from package.
    # This is a special writer to allow for a single glob or a list of globs.
    def exclude=(val)
      @exclude = [val].flatten
    end

    # Set file patterns to ignore.
    # This is a special writer to allow for a single glob or a list of globs.
    def ignore=(val)
      @ignore = [val].flatten
    end

    #
    def initialize_defaults
      super
      @manifest   = project.root.glob('MANIFEST{,.txt}', :casefold).first
      @types      = DEFAULT_TYPES
      @distribute = DEFAULT_INCLUDE
      @exclude    = DEFAULT_EXCLUDE
      @ignore     = DEFAULT_IGNORE
      @spec       = false
    end

    # Check for available MANIFEST file if needed.
    def preconfigure
      if !remanifest && !manifest #project.root.glob('MANIFEST{,.txt}', :casefold).first
        abort "No Manifest file available for Box.\nUse 'remanifest' option or create a MANIFEST file."
      end
    end

    # Generate package.
    def package
      require 'box'

      loc = Dir.pwd

      # DEPRECATE: safe option is replaced by dryrun
      opts = {
        :force  => force?,
        :dryrun => dryrun?,
        :safe   => dryrun?,
        :spec   => spec
      }

      create_manifest if remanifest? #(*files)

      types.each do |type|
        case type
        when 'zip'
          status("zip -r #{package_name}.zip .")
          box = ::Box::Zip.new(loc, opts)
        when 'tar'
          status("tar -cz #{package_name}.tar.gz .")
          box = ::Box::Gz.new(loc, opts)
        when 'gem'
          status("gem build #{package_name}.gem .")
          box = ::Box::Gem.new(loc, opts)
        end
        box.package
      end

      #report_package_built(file)
    end

    # Returns package name from metadata. This
    # is generally in the form or +#{package}-#{version}+.
    def package_name
      metadata.package_name
    end

    # Generate a manifest.
    #
    # TODO: Use Mast?
    # TODO: Compare manifests and skip overwrite if they are the same?
    #
    def create_manifest #(*files)
      return if dryrun?
      manifest_file = manifest || 'MANIFEST'
      #
      files = files().flatten.compact
      files = ['**/*'] if files.empty?
      #Dir.chdir(project.root) do
        files = multiglob(*files).sort
        rm(manifest_file) if File.exist?(manifest_file)
        File.open(manifest_file, 'w') do |f|
          f << files.join("\n")
        end
      #end
    end

    # List of files included in the package. This is generated
    # using +include+ and +exlude+.
    #
    def files
      @files ||= collect_files(true)
    end

    # Collect distributable files. This methid is called
    # and cached by #files.
    #
    def collect_files(with_dirs=false)
      files = []

      Dir.chdir(project.source) do
        files += Dir.multiglob_r(*distribute)
        files -= Dir.multiglob_r(*remove)
        files -= Dir.multiglob_r(*ignore)

        #files -= Dir.multiglob_r(*ignore) # TODO: shoud be based on basename
        #files = files.reject{ |f| ignore.any?{ |i| File.fnmatch?(i, File.basename(f)) } }

        #files -= Dir.multiglob_r(project.pack.to_s) #package_directory
      end

      # do not include symlinks
      files.reject!{ |f| FileTest.symlink?(f) }

      # option to exclude directories for list
      unless with_dirs
        files = files.select{ |f| !File.directory?(f) }
      end

      return files
    end

    # Combines exclude and ignore into a single pattern list.
    # Ignore patterns are just exclude patterns applied to the basename.
    def remove
      exclude + ignore.map{ |i| File.join('**', i) }
    end

  end

end
