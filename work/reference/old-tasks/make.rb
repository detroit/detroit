#require 'reap/project/compile'

module Reap

  class Project

    # The Make tool routes to extension Makefile(s).
    # Presently, it is designed to support only extconf.rb design.
    #
    # TODO: win32 cross-compile ?

    MAKE_COMMAND = ENV['make'] || (RUBY_PLATFORM =~ /(win|w)32$/ ? 'nmake' : 'make')


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

    def make
      make_config
      make_target
    end

    # Compile static.

    def make_static
      make_config
      make_target 'static'
    end

    # Remove enouhg compile products for a clean compile.

    def make_clean
      make_target 'clean'
    end

    # Remove all compile products.

    def make_distclean
      make_target 'distclean'
      extensions.each do |directory|
        makefile = File.join(directory, 'Makefile')
        rm(makefile) if File.exist?(makefile)
      end
    end

    alias_method :clobber_make, :make_distclean

    # Create Makefile(s).

    def make_config
      extensions.each do |directory|
        next if File.exist?(File.join(directory, 'Makefile'))
        cd(directory) do
          sh "ruby extconf.rb"
        end
      end  
    end

    private

    def make_target(target='')
      extensions.each do |directory|
        cd(directory) do
          sh "#{MAKE_COMMAND} #{target}"
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
