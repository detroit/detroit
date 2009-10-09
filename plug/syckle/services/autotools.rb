module Syckles

  # = Autotools Compile Plugin
  #
  # The Autotools plugin utilizes extconf.rb and
  # standard Makefile(s) to compile extensions.
  #
  # TODO: win32 cross-compile ?
  #
  class Autotools < Service

    cycle :main, :compile
    cycle :main, :reset
    cycle :main, :clean

    #available do |project|
    #  # check for make tools
    #end

    #autorun do |project|
    #  project.compiles?
    #end

    #
    MAKE_COMMAND = ENV['make'] || (RUBY_PLATFORM =~ /(win|w)32$/ ? 'nmake' : 'make')

    # Compile statically? Applies only to compile method. (false)
    attr_accessor :static

    #
    def initialize_defaults
      @static = false
    end

    # Check to see if this project has extensions that need to be compiled.

    def compiles?
      !extensions.empty?
    end

    # Extension directories. Often this will simply be 'ext'.
    # but sometimes more then one extension is needed and are kept
    # in separate directories. This works by looking for ext/**/*.c
    # files, where ever they are is considered an extension directory.

    def extensions
      @extensions ||= Dir['ext/**/*.c'].collect{ |file| File.dirname(file) }.uniq
    end

    # Compile extensions.

    def compile
      configure
      if static
        make 'static'
      else
        make
      end
    end

    # Remove enough compile products for a clean compile.

    def clean
      make 'clean'
    end

    #alias_method :clean, :make_clean

    # Remove all compile products.

    def distclean
      make 'distclean'
      extensions.each do |directory|
        makefile = File.join(directory, 'Makefile')
        rm(makefile) if File.exist?(makefile)
      end
    end

    alias_method :clobber, :distclean

    # Create Makefile(s).

    def configure
      extensions.each do |directory|
        next if File.exist?(File.join(directory, 'Makefile'))
        report "configuring #{directory}"
        cd(directory) do
          sh "ruby extconf.rb"
        end
      end
    end

  private

    def make(target='')
      extensions.each do |directory|
        report "compiling #{directory}"
        cd(directory) do
          shell "#{MAKE_COMMAND} #{target}"
        end
      end
    end

    # Eric Hodel said NOT to copy the compiled libs.
    #
    #task :copy_files do
    #  cp "ext/**/*.#{dlext}", "lib/**/#{arch}/"
    #end
    #
    #def dlext
    #  Config::CONFIG['DLEXT']
    #end
    #
    #def arch
    #  Config::CONFIG['arch']
    #end

    # Cross-compile for Windows. (TODO)

    #def make_mingw
    #  abort "NOT YET IMPLEMENTED"
    #end

  end

end


