module Reap

  class Project

    # Verify syntax of ruby scripts.
    #
    # This takes one option +:scripts+ which is a glob or list of globs
    # of the scripts to check. By default this is all scripts in the libpath(s).

    def check_syntax(options=nil)
      options = configure_options(options, 'check-syntax', 'check')

      libpath = options['loadpath'] || metadata.loadpath
      exclude = options['exclude']

      #libpath = libpath.split(/[:;]/) unless Array===libpath
      libpath = list_option(libpath)
      exclude = list_option(exclude)

      files   = multiglob_r(*libpath) - multiglob_r(exclude)
      files   = files.select{ |f| File.extname(f) == '.rb' }
      max     = files.collect{ |f| f.size }.max
      list    = []

      files.each do |s|
        next unless File.file?(s)
        #if not system "ruby -c -Ibin:lib:test #{s} &> /dev/null" then
        r = system "ruby -c -I#{libpath} #{s} > /dev/null 2>&1"
        if r
          puts("%-#{max}s  [PASS]" % [s]) #if verbose?
        else
          puts("%-#{max}s  [FAIL]" % [s]) #if verbose?
          list << s #:syntax
        end
      end

      puts "  #{list.size} Syntax Errors"

      if verbose?
        unless list.empty?
          puts "\n-- Syntax Errors --\n"
          list.each do |f|
            print "* "
            system "ruby -c -I#{libpath} #{f} 2>&1"
            #puts
          end
          puts
        end
      end
    end

    # Load each script independently to ensure there are no
    # require dependency issues.
    #
    # WARNING! You should only run this on scripts that have no
    # toplevel side-effects!!!
    #
    # This takes one option +:scripts+ which is a glob or list of globs
    # of the scripts to check. By default this is all scripts in the libpath(s).
    #
    # FIXME: This isn't routing output to dev/null as expected ?

    def check_load(options=nil)
      options = configure_options(options, 'check-load', 'check')

      make if compiles?

      libpath = options['libpath'] || metadata.libpath
      exclude = options['exclude']

      libpath = list_option(libpath)
      exclude = list_option(exclude)

      files = multiglob_r(*libpath) - multiglob_r(exclude)
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

  end

end
