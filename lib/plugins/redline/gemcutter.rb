module Redline::Plugins

  # = GemCutter Service
  #
  # This plugin is used to release gems via gemcutter.org.
  #
  class GemCutter < Service

    cycle :main, :release

    ## How to autorun gemcutter?
    #autorun do |project|
    #  /gemcutter.org/i =~ project.metadata.download
    #end

    # Location of packages. This defaults to Project#pack.
    attr :pkgdir

    # Version to release. Defaults to current version.
    attr :version

    # Additional commandline options string passed to gem command.
    #attr :options

    #
    def initialize_defaults
      @pkgdir  = project.pack
      @version = project.metadata.version
    end

    #
    def release
      pkgs = Pathname.new(pkgdir).glob("*-#{version}.gem")
      if pkgs.empty?
        report "No .gem packages found for version {version} at #{pkgdir}."
      else
        pkgs.each do |file|
          sh "gem push #{file}"
        end
      end
    end

    # Require rubygems library
    #
    #def require_rubygems
    #  begin
    #    require 'rubygems/specification'
    #    ::Gem::manage_gems
    # rescue LoadError
    #    raise LoadError, "RubyGems is not installed."
    # end
    #end

  end

end

