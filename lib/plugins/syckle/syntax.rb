module Syckle::Plugins

  # = Syntax Checker Plugin
  #
  # The Syntax plugin simply checks all Ruby code for
  # syntax errors. It's a rather trivial tool, and is
  # here simply for example sake.
  #
  class Syntax < Service

    cycle :main, :analyize

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Add these folders to the $LOAD_PATH.
    def loadpath
      @loadpath
    end

    # Lib files to exclude.
    def exclude
      @exclude
    end

    #
    def loadpath=(x)
      @loadpath = x.to_list
    end

    #
    def exclude=(x)
      @exclude = x.to_list
    end

    #
    def initialize_defaults
      @loadpath = metadata.loadpath
      @exclude  = []
    end

    # Verify syntax of ruby scripts.
    #
    # This takes one option +:scripts+ which is a glob or list of globs
    # of the scripts to check. By default this is all scripts in the libpath(s).
    #
    def analyize
      #loadpath = options['loadpath'] || loadpath()
      #exclude  = options['exclude']  || exclude()

      loadpath = self.loadpath.to_list
      exclude  = self.exclude.to_list

      files   = multiglob_r(*loadpath) - multiglob_r(exclude)
      files   = files.select{ |f| File.extname(f) == '.rb' }
      max     = files.collect{ |f| f.size }.max
      list    = []

      logfile = project.log + 'syntax.log'

      if logfile.outofdate?(*files) or force?
        io.puts "Started"

        start = Time.now

        files.each do |file|
          pass = syntax_check_file(file, max)
          list << file if !pass
        end

        io.puts "\nFinished in %.6f seconds." % [Time.now - start]
        io.puts "\n#{list.size} Syntax Errors"

        log_syntax_errors(list)
      else
        io.puts "Syntax check is up to date."
      end
    end

    #
    def syntax_check_file(file, max=nil)
      return unless File.file?(file)
      max  = max || file.size + 2
      #libs = loadpath.join(';')
      #r = system "ruby -c -Ibin:lib:test #{s} &> /dev/null"
      r = system "ruby -c -I#{libsI} #{file} > /dev/null 2>&1"
      if r
        if verbose?
          io.printline("%-#{max}s" % file, "[PASS]")
        else
          io.print '.'
        end
        true
      else
        if verbose?
          io.printline("%-#{max}s" % file, "[FAIL]")
          #puts("%-#{max}s  [FAIL]" % [s])
        else
          io.print 'E'
        end
        false
      end
    end

    #
    def log_syntax_errors(list)
      logfile = project.log + 'syntax.log'
      if list.empty?
         logfile.write('') #logfile.clear
      else
        io.puts "\n-- Syntax Errors --\n"
        list.each do |file|
          io.print "* #{file}"
          err = `ruby -c -I#{libsI} #{file} 2>&1`
          io.puts(err) if verbose?
          logfile.write("=== #{file}\n#{err}\n\n")
        end
      end
    end

    private

    #
    def libsI
      loadpath.join(';')
    end

  end

end

=begin
    # Load each script independently to ensure there are no
    # require dependency issues.
    #
    # WARNING! You should only run this on scripts that have no
    # toplevel side-effects!!!
    #
    # This takes one option +:libpath+ which is a glob or list of globs
    # of the scripts to check. By default this is all scripts in the libpath(s).
    #
    # FIXME: This isn't routing output to dev/null as expected ?

    def check_load(options={})
      #options = configure_options(options, 'check-load', 'check')

      make if compiles?

      libpath = options['libpath'] || loadpath()
      exclude = options['exclude'] || exclude()

      libpath = libpath.to_list
      exclude = exclude.to_list

      files = multiglob_r(*libpath) - multiglob_r(*exclude)
      files   = files.select{ |f| File.extname(f) == '.rb' }
      max   = files.collect{ |f| f.size }.max
      list  = []

      files.each do |s|
        next unless File.file?(s)
        #if not system "ruby -c -Ibin:lib:test #{s} &> /dev/null" then
        cmd = "ruby -I#{libpath.join(':')} #{s} > /dev/null 2>&1"
        puts cmd if debug?
        if r = system(cmd)
          puts "%-#{max}s  [PASS]" % [s]
        else
          puts "%-#{max}s  [FAIL]" % [s]
          list << s #:load
        end
      end

      puts "  #{list.size} Load Failures"

      if verbose?
        unless list.empty?
          puts "\n-- Load Failures --\n"
          list.each do |f|
            print "* "
            system "ruby -I#{libpath} #{f} 2>&1"
            #puts
          end
          puts
        end
      end
    end

=end

