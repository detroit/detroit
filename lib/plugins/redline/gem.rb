module Redline::Plugins

  # = Gem Builder Plugin
  #
  # This plugin generate a gem package.
  #
  class Gem < Service

    pre_stop :main, :package do
      prepackage
    end

    stop :main, :package

    # The .gemspec filename (default looks up .gemspec file or {name}.gemspec).
    attr_accessor :gemspec

    # True or false whether to build .gemspec via POM metadata (default is `true`).
    attr_accessor :pom

    # Package directory (defaults to `pkg`).
    attr_accessor :pkgdir

    #
    def prepackage
      create_gemspec if pom
    end

    # TODO: make pure ruby
    def package
      #`gem build #{gemspec}`
      spec    = load_gemspec
      builder = ::Gem::Builder.new(spec)
      package = builder.build
      mv(package, pkgdir)
    end

    private

    #
    def initialize_defaults
      @pom = true if @pom.nil?
      @pkgdir  ||= project.pkg
      @gemspec ||= lookup_gemspec
    end

    #
    def create_gemspec
      require 'pom/gemspec'
      yaml = project.to_gemspec.to_yaml
      File.open(gemspec, 'w') do |f|
        f << yaml
      end
      status File.basename(gemspec) + " updated."
    end

    #
    def lookup_gemspec
      dot_gemspec = (project.root + '.gemspec').to_s
      if File.exist?(dot_gemspec)
        dot_gemspec.to_s
      else
        project.metadata.name + '.gemspec'
      end
    end

    #
    def load_gemspec
      file = gemspec
      if yaml?(file)
        ::Gem::Specification.from_yaml(File.new(file))
      else
        ::Gem::Specification.load(file)
      end
    end

    #
    def yaml?(file)
      line = open(file) { |f| line = f.gets }
      line.index "!ruby/object:Gem::Specification"
    end

    #
    #def require_rubygems
    #  begin
    #    require 'rubygems'
    #  rescue LoadError
    #    $stderr.puts "Oh no! No RubyGems!"
    #  end
    #end

  end

end
