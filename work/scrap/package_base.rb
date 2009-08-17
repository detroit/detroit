require 'facets/platform'

module Reap

  class PackService < Service

    PACKAGE_STORE = 'pkg'

    # Create TestUnit class based on project.

    def self.from_project(project, options)
      metadata = project.metadata.clone
      new(metadata, options)
    end

    # Returns the package storage directory (now constant 'pkg').

    def package_store
      PACKAGE_STORE
    end

    # Current platform.

    def current_platform
      Platform.local.to_s
    end

    # Prepare for packaging (clean, distclean, version stamp).
    #
    # TODO: When we add support for binary packages distclean
    #       should not be done for them.

    def prepare(options)
      @prepared ||= (
        project.clean
        project.make_distclean if project.compiles?
        project.stamp(options)
        true
      )
    end

    private

      #

      def package_prepare_stage(extension, options)
        prepare(options)

        metadata = metadata().clone
        metadata.update(options)

        abort "No name"     unless metadata.name
        abort "No version"  unless metadata.version

        fname = metadata.stage_name

        if project.compiles?
          streams = verbose? ? [] : [STDOUT, STDERR]
          silence_stream(*streams) do
            project.call(:make_distclean)
            # If platform package then pre-compile
            if options['platform']
              project.call(:make)
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
      #
      def transfer(file, store=nil)
        store ||= package_folder
        # move to store, unless already there
        dest = File.join(store, File.basename(file))
        dest = File.expand_path(dest)
        mv(file, store) unless file == dest
      end

      # Generate manifest.
      #
      def package_manifest(dir, files='**/*')
        return if dryrun?
        Dir.chdir(dir) do
          files = Dir[files]
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

