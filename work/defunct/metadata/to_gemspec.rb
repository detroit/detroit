=begin
module Reap

  class Metadata

    # Create Gem::Specification
    #
    # NOTE: I don't quite get how Rubygems deals with authors.
    #       It turns a singel value into an array. Why?
    #       author = [metadata.author, metadata.contact].flatten.compact.first
    #
    def to_gemspec
      metadata = self

      # Make sure RubyGems is loaded.
      begin
        Kernel.require 'rubygems/specification'
        ::Gem::manage_gems
      rescue LoadError
        raise LoadError, "RubyGems is not installed?"
      end

      # FIXME: this only works b/c of package staging
      distribute = Dir.glob('**/*')  #project.filelist

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
        spec.test_files = distribute.select{ |f| f =~ /^test\// }
      end

    end

  end

end
=end

