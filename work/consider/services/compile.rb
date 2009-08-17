# The Make tool routes to extension Makefile(s).
# At this point it's designed to support extconf.rb design.
#
# TODO: Perhaps make a true compiler class in the future.
# TODO: win32 cross-compile.

require 'rbconfig'

module Reap

  class Manager

    # We can't use Ruby's standard build procedures
    # on Windows because the Ruby executable is
    # built with VC++ while here we want to build
    # with MingW.  So just roll our own...

    RUBY_INCLUDE_DIR = Config::CONFIG["archdir"]
    RUBY_BIN_DIR = Config::CONFIG["bindir"]
    RUBY_LIB_DIR = Config::CONFIG["libdir"]

    if RUBY_PLATFORM =~ /(win|w)32$/
      RUBY_SHARED_LIB = Config::CONFIG["LIBRUBY"].gsub(/lib$/, 'dll')
    else
      RUBY_SHARED_LIB = Config::CONFIG["LIBRUBY"]
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

    #

    def compile(options=nil)
      extensions.each do |extdir|
        cd(extdir) do
          src = Dir['*.c']

          src.each do |srcfile|
            #File.basename(file_name).ext('o')
            objfile = File.basename(srcfile).chomp(File.extname(srcfile)) + '.o'
            compile_object(srcfile, objfile)
          end

          obj = Dir['*.o']

          ext = "ruby_prof.so" # how to get ?

          sh "gcc -shared -o #{ext} #{obj} #{RUBY_BIN_DIR}/#{RUBY_SHARED_LIB}"
        end
      end
    end

    def compile_object(objfile, srcfile)
      sh "gcc -c -fPIC -O2 -Wall -o #{objfile} #{srcfile} -I#{RUBY_INCLUDE_DIR}"
    end

    def compile_clean
      extensions.each do |extdir|
        cd(extdir) do
          Dir['*.o'].each do { |f| rm(f) }
        end
      end
    end

    def compile_clobber
      compile_clean
      extensions.each do |extdir|
        cd(extdir) do
          Dir['*.so'].each do { |f| rm(f) }
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
