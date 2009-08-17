#require 'facets/project/package'

module Reap

  class Project

    # Remove gem package products.

    def gem_clobber(options=nil)
      store = "pkg"

      packages = glob(File.join(store, '*.gem'))

      packages.each do |path|
        File.directory?(path) ? rm_r(path) : rm(path)
      end
    end

    # Create a Gem package.
    #
    # TODO: Should this use staging too, like zip/tgz?

    def gem_package(options=nil)
      return package_gem(options=nil)
    end

    # Install gem package, creating the package if not already created.
    #
    # TODO: Endure that we even need a gem package using #out_of_date?

    def gem_install(options=nil)
      file = gem_package(options)
      sh "gem install #{file}"
    end

    # Uninstall gem package.
    #
    # TODO: Sepcify version?

    def gem_uninstall
      i = metadata.package_name.rindex('-')
      name, version = metadata.package_name[0...i], metadata.package_name[i+1..-1]
      sh "gem uninstall #{name} -v #{version}"
    end

    private

    # Create Gem::Specification.

    def gemspec(package)
      distribute = package.filelist
      #distribute = Dir.multiglob_with_default( '**/*', distribute )

      # I don't quite get how Rubygems deals with authors. It turns a singel value into an array. Why?
      #author = [package.author, package.contact].flatten.compact.first

      if md = /(\w+).rubyforge.org/.match(package.homepage)
        rubyforge_project = md[1]
      else
        rubyforge_project = package.project  # b/c it has to be something according to Eric Hodel.
      end

      ::Gem::Specification.new do |spec|
        spec.name              = package.package
        spec.version           = package.version
        spec.summary           = package.brief
        spec.description       = package.description
        spec.author            = package.contact
        spec.email             = package.email
        spec.rubyforge_project = rubyforge_project
        spec.homepage          = package.homepage

        spec.platform          = package.platform  #'ruby'

        spec.require_paths = [package.loadpath].flatten

        #if package.platform != 'ruby'
        #  spec.require_paths.concat(spec.require_paths.collect{ |d| File.join(d, platform) })
        #end

        spec.bindir = "bin"
        spec.executables  = package.executables
        spec.requirements = package.requirements

        if package.dependencies
          package.dependencies.each do |d,v|
            spec.add_dependency(*[d,v].compact)
          end
        end

        spec.extensions = [package.extensions].flatten.compact

        # rdocs (argh!)

        readme = Dir.glob('README{,.txt}', File::FNM_CASEFOLD).first

        spec.has_rdoc = package.autodoc  # Make true always?

        rdocfiles = []
        rdocfiles << readme if readme
        rdocfiles.concat(Dir['[A-Z]*'] || [])  # package.document
        rdocfiles.uniq!
        spec.extra_rdoc_files = rdocfiles

        rdoc_options = ['--inline-source']
        rdoc_options.concat ["--title", package.title] if package.title
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
    #  r << "\n  Name: #{package.name}"
    #  r << "\n  Version: #{package.version}"
    #  r << "\n  File: #{File.basename(file)}"
    #  say r
    #end

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
