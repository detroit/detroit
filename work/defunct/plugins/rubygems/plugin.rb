require 'reap/plugins/base_pack'
#require 'reap/metadata/to_gemspec'

module Reap
module Plugins

  # = RubyGems Package Plugin
  #
  # Gem utility encapsulates RubyGems package creation.
  #
  class Gem < Plugin::PackPlugin

    pipeline :main, :package
    pipeline :main, :reset

    # Create a gemspec file (in the project's root directory)?
    attr_accessor :gemspec
    alias_method :gemspec?, :gemspec

    #
    def extension ; '.gem' ; end

    # Create a RubyGems package.
    #
    # This converts the project's metadata into a gemspec
    # and run's it through the Gem::Builder. It does not
    # shellout.
    #
    # TODO: This uses staging too, like zip/tgz, should it?
    #
    def package
      require_rubygems

      unless package_needed? or force?
        report_package_already_built(package_file)
        return
      end

      if dryrun?
        status("gem build #{stage_folder}")
        return
      end

      # <-- binary stuff here?

      # generate manifest in root directory
      package_manifest(project.root, filelist)

      file = nil
      #stage(extension) do
        gemspec = create_gemspec

        if gemspec?
          file = project.root + "#{gemspec.name}.gemspec"
          file_write(file, gemspec.to_yaml) unless pretend?
        end

        builder = ::Gem::Builder.new(gemspec)  # can we do this outside stage?

        status "gem build at #{stage_folder}"

        silence_stream(STDOUT, STDERR) do
          file = builder.build
        end

        file = File.expand_path(file)
      #end

      file = transfer(file, project.pack)

      report_package_built(file)

      return file
    end

    # Remove gem packages. This will remove all *.gem packages
    # found in the package folder.
    #
    def reset(options=nil)
      packages = Dir.glob(File.join(project.pack, '*.gem'))
      packages.each do |path|
        rm(path) if File.file?(path)
      end
    end

    # Require RubyGems library.
    #
    def require_rubygems
      begin
        require 'rubygems/specification'
#        ::Gem::manage_gems
      rescue LoadError
        raise LoadError, "RubyGems is not installed."
      end
    end

    # Install gem package, creating the package if not already created.
    #
    # TODO: Endure that we even need a gem package using #out_of_date?

    def install_gem
      file = package()
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

    # Create Gem::Specification
    #
    # NOTE: I don't quite get how Rubygems deals with authors.
    #       It turns a single value into an array. Why?
    #       author = [metadata.author, metadata.contact].flatten.compact.first
    #
    def create_gemspec
      # Make sure RubyGems is loaded.
      #begin
      #  Kernel.require 'rubygems/specification'
      #  ::Gem::manage_gems
      #rescue LoadError
      #  raise LoadError, "RubyGems is not installed?"
      #end

      # FIXME: this only works b/c of package staging
      #distribute = Dir.glob('**/*')
      #distribute = project.filelist
      distribute = project.manifest.files

      if md = /(\w+).rubyforge.org/.match(metadata.homepage)
        rubyforge_project = md[1]
      else
        rubyforge_project = metadata.name  # b/c it has to be something according to Eric Hodel.
      end

      ::Gem::Specification.new do |spec|
        spec.name              = metadata.name
        spec.version           = metadata.version
        spec.summary           = metadata.summary
        spec.description       = metadata.description
        spec.authors           = [metadata.contact, metadata.authors].flatten.compact.uniq
        spec.email             = metadata.email
        spec.rubyforge_project = rubyforge_project
        spec.homepage          = metadata.homepage
        spec.platform          = metadata.platform  #'ruby'

        spec.require_paths     = [metadata.loadpath].flatten

        #if metadata.platform != 'ruby'
        #  spec.require_paths.concat(spec.require_paths.collect{ |d| File.join(d, platform) })
        #end

        spec.bindir = "bin"
        spec.executables  = metadata.executables
        spec.requirements = metadata.notes

        if metadata.require
          metadata.require.each do |d,v|
            d,v = *d.split(/\s+/) unless v
            spec.add_dependency(*[d,v].compact)
          end
        end

        spec.extensions = [metadata.extensions].flatten.compact

        # rdocs (argh!)

        readme = Dir.glob('README{,.txt}', File::FNM_CASEFOLD).first

        spec.has_rdoc = true #metadata.autodoc  # Make true always?

        rdocfiles = []
        rdocfiles << readme if readme
        rdocfiles.concat(Dir['[A-Z]*'] || [])  # metadata.document
        rdocfiles.uniq!
        spec.extra_rdoc_files = rdocfiles

        rdoc_options = ['--inline-source']
        rdoc_options.concat ["--title", "#{metadata.name} api"] #if metadata.title
        rdoc_options.concat ["--main", readme] if readme
        spec.rdoc_options = rdoc_options

        spec.files = distribute

        # TODO make test_files configurable (?)
        spec.test_files = distribute.select do |f|
          File.basename(f) =~ /test/ && File.extname(f) == '.rb'
        end
      end

    end

  end

end
end


