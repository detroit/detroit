module Reap
class Plugin

  # = Pack Plugin Base Class
  #
  # Subclass of Service provides a base class for packaging services.
  #
  # Currentlly hidden files can't be included in a package.
  #
  # TODO: Use FileList instead of glob (?)
  # TODO: Imporve how files to include/exclude ar selected
  #
  class PackPlugin < Plugin

    # Directories that a typically excluded from a distribution.
    DEFAULT_EXCLUDE = %{ doc/log log gen temps site tmp web website work }

    # File pattern are files/dirs that are typically ignored.
    DEFAULT_IGNORE  = %{ .* }

    # List of files and/or directories to include in package.
    attr_accessor :distribute

    # Alias for #distribute.
    alias_accessor :include, :distribute

    # List of files and/or directories to exclude from package.
    attr_accessor :exclude

    # Standard files to ignore. Defaults to hidden files (.*).
    attr_accessor :ignore

    def initialize_defaults
      super
      @distribute = ['**/*']
      @exclude    = DEFAULT_EXCLUDE
      @ignore     = DEFAULT_IGNORE
    end

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    def extension
      raise "must override #extension"
    end

    # Glob of files to be distributed in package.
    # This can be a single glob or a list of globs.
    # The default is '**/*'.
    def distribute=(val)
      @distribute = [val].flatten
    end

    # Glob of files to be exclude from package.
    # This can be a single glob or a list of globs.
    # The default is to exclude the 'admin' directory.
    def exclude=(val)
      @exclude = [val].flatten
    end

    # Prepare for packaging (clean, distclean, version stamp).
    #
    # TODO: When we add support for binary packages distclean
    #       should not be done for them.

    #def prepare(options)
    #  @prepared ||= (
    #    project.clean
    #    project.make_distclean if project.compiles?
    #    project.stamp(options)
    #    true
    #  )
    #end

    private

    def package_file
      metadata.stage_name + extension
    end

    # If the package needed? ie. Is it not already created?
    #
    def package_needed?
      pfile = File.join(project.pack, package_file)
      files = filelist
      outofdate?(pfile, *files) # or force?
    end

    # If the package needed? ie. Is it not already created?
    #
    #def package_needed?(extension)
    #  pfile = File.join(project.pack, metadata.stage_name + extension)
    #  files = filelist
    #  outofdate?(pfile, *files) # or force?
    #end

    #
    def package_exist?(extension)
      !package_needed?(extension)
    end

    def stage_name
      metadata.stage_name
    end

    # Create staging ground.
    #
    # TODO: Do we need a clean phase that this can call on?
    #       Hmm... maybe a clean phase should occur before package phase?
    def stage(extension, &block)
      fname = metadata.stage_name
      stage = File.join(project.tmp, fname)
      #pfile = stage + extension

      files = filelist

      #clean # TODO: Need to handle general clean service --an how to access from here?

      rm_r(stage) if File.exist?(stage)  # remove old stage

      super(stage, files)                # make new stage

      package_manifest(stage, '**/*')    # generate stage manifest

      chdir(stage) do
        block.call if block
      end
    end

    #alias_method :stage_create, :stage

    # List of files included in the package. This is generated using
    # ++include++ and ++exlude++.
    #
    def filelist
      @filelist ||= collect_files(true)
    end

    # Collect distribution files.
    #
    def collect_files(with_dirs=false)
      files = []

      Dir.chdir(project.source) do
        files += Dir.multiglob_r(*distribute)
        files -= Dir.multiglob_r(*exclude)
        files -= Dir.multiglob_r(*ignore)
        #files -= Dir.multiglob_r(project.pack.to_s) #package_directory
      end

      # Do not include symlinks.
      files.reject!{ |f| FileTest.symlink?(f) }
      # Option to exclude directories
      unless with_dirs
        files = files.select{ |f| !File.directory?(f) }
      end
      return files
    end

    # Transfer package file to storage location.

    def transfer(file, store=nil)
      store ||= project.pack
      # move to store, unless already there
      from = File.expand_path(file)
      dest = File.expand_path(File.join(store, File.basename(file)))
      unless from == dest
        mkdir_p store
        mv(file, store)
      end
      return dest
    end

    # Generate manifest.

    #def package_manifest(dir, files='**/*')
    #  return if dryrun?
    #  Dir.chdir(dir) do
    #    files = Dir[files]
    #    rm('MANIFEST') if File.exist?('MANIFEST')
    #    File.open('MANIFEST', 'w') do |f|
    #      f << files.join("\n")
    #    end
    #  end
    #end

    # Generate manifest.
    #
    def package_manifest(dir, *files)
      return if dryrun?
      files = files.flatten.compact
      files = ['**/*'] if files.empty?
      Dir.chdir(dir) do
        files = multiglob(*files)
        rm('MANIFEST') if File.exist?('MANIFEST')
        File.open('MANIFEST', 'w') do |f|
          f << files.join("\n")
        end
      end
    end

    #
    def stage_folder
      File.join(project.tmp, metadata.stage_name)
    end

    # Report that a package has been built.
    # FIXME: will type, name and version always be right?

    def report_package_built(file)
      file = File.basename(file)
      type = File.extname(file)
      name = file[0...file.rindex('-')]
      vers = file[file.rindex('-')+1..-1].chomp(type)

      puts
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

      puts
      puts "  Package #{file} is already current."
      puts
      #puts "  Name: #{name}"
      #puts "  Version: #{vers}"
      #puts "  File: #{file}"
    end

  end

end
end

