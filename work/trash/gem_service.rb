require 'reap/service/pack'

module Reap

  class Gem < PackService

    #service_action :package
    #service_action :package_gem
    #service_action :clobber
    #service_action :clobber_gem


    # Remove gem package products.

    def clobber(options=nil)
      store = "pkg"

      packages = glob(File.join(store, '*.gem'))

      packages.each do |path|
        File.directory?(path) ? rm_r(path) : rm(path)
      end
    end

    def clobber_gem ; clobber ; end

    # Create a Gem package.
    #
    # TODO: This uses staging too, like zip/tgz, should it?

    def package(options=nil)
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

    def package_gem ; package ; end

    # Install gem package, creating the package if not already created.
    #
    # TODO: Endure that we even need a gem package using #out_of_date?

    def install_gem(options=nil)
      file = gem_package(options)
      sh "gem install #{file}"
    end

    # Uninstall gem package.
    #
    # TODO: Sepcify version?

    def uninstall_gem
      i = metadata.package_name.rindex('-')
      name, version = metadata.package_name[0...i], metadata.package_name[i+1..-1]
      sh "gem uninstall #{name} -v #{version}"
    end

    private

    # Create Gem::Specification.

    def gemspec(metadata)
      distribute = metadata.filelist
      #distribute = Dir.multiglob_with_default( '**/*', distribute )

      # I don't quite get how Rubygems deals with authors. It turns a singel value into an array. Why?
      #author = [metadata.author, metadata.contact].flatten.compact.first

      if md = /(\w+).rubyforge.org/.match(metadata.homepage)
        rubyforge_project = md[1]
      else
        rubyforge_project = metadata.project  # b/c it has to be something according to Eric Hodel.
      end

      ::Gem::Specification.new do |spec|
        spec.name              = metadata.package
        spec.version           = metadata.version
        spec.summary           = metadata.brief
        spec.description       = metadata.description
        spec.author            = metadata.contact
        spec.email             = metadata.email
        spec.rubyforge_project = rubyforge_project
        spec.homepage          = metadata.homepage

        spec.platform          = metadata.platform  #'ruby'

        spec.require_paths = [metadata.loadpath].flatten

        #if metadata.platform != 'ruby'
        #  spec.require_paths.concat(spec.require_paths.collect{ |d| File.join(d, platform) })
        #end

        spec.bindir = "bin"
        spec.executables  = metadata.executables
        spec.requirements = metadata.requirements

        if metadata.dependencies
          metadata.dependencies.each do |d,v|
            spec.add_dependency(*[d,v].compact)
          end
        end

        spec.extensions = [metadata.extensions].flatten.compact

        # rdocs (argh!)

        readme = Dir.glob('README{,.txt}', File::FNM_CASEFOLD).first

        spec.has_rdoc = metadata.autodoc  # Make true always?

        rdocfiles = []
        rdocfiles << readme if readme
        rdocfiles.concat(Dir['[A-Z]*'] || [])  # metadata.document
        rdocfiles.uniq!
        spec.extra_rdoc_files = rdocfiles

        rdoc_options = ['--inline-source']
        rdoc_options.concat ["--title", metadata.title] if metadata.title
        rdoc_options.concat ["--main", readme] if readme
        spec.rdoc_options = rdoc_options

        spec.files = distribute

        # TODO make test_files configurable (?)
        spec.test_files = distribute.select{ |f| f =~ /^test\// }
      end
    end

    # Report that a package has been built.
    # FIXME

    #def report_package_built(type, file)
    #  r = ''
    #  r << "\n  Successfully built #{type}"
    #  r << "\n  Name: #{metadata.name}"
    #  r << "\n  Version: #{metadata.version}"
    #  r << "\n  File: #{File.basename(file)}"
    #  say r
    #end

  end

end

