module Redline::Plugins

  # = Test::Unit Plugin via testrb
  #
  # This service plugin runs your test/unit (or minitest)
  # tests based unit tests using the +testrb+ commandline tool.
  #
  # TODO: How to abort lifecycle if fail?
  #
  class Testrb < Service

    cycle :main, :test do
      runtests
    end

    #available do |project|
    #  !Dir['test/**/*.rb'].empty?
    #end

    # Default test file patterns.
    DEFAULT_TESTS = ["test/**/test_*.rb", "test/**/*_test.rb" ]

    # File glob pattern of tests to run.
    attr_accessor :tests

    # Test file patterns to specially exclude.
    attr_reader :exclude

    # Add these folders to the $LOAD_PATH.
    attr_reader :loadpath

    # Libs to require when running tests.
    attr_reader :requires

    # Test against live install (i.e. Don't use loadpath option).
    attr_accessor :live

    # Special writer to ensure the value is a list.
    def loadpath=(val)
      @loadpath = val.to_list
    end

    # Special writer to ensure the value is a list.
    def exclude=(val)
      @exclude = val.to_list
    end

    # Special writer to ensure the value is a list.
    def requires=(val)
      @requires = val.to_list
    end

    # In case you forget the 's'.
    alias_method :require=, :requires=

  private

    # Setup default attribute values.
    def initialize_defaults
      @loadpath = metadata.loadpath
      @tests    = DEFAULT_TESTS
      @exclude  = []
      @reqiures = []
      @live     = false
    end

    # Collect test configuation.
    #def test_configuration(options=nil)
    #  #options = configure_options(options, 'test')
    #  #options['loadpath'] ||= metadata.loadpath
    #
    #  options['tests']    ||= self.tests
    #  options['loadpath'] ||= self.loadpath
    #  options['requires'] ||= self.requires
    #  options['live']     ||= self.live
    #  options['exclude']  ||= self.exclude
    #
    #  #options['tests']    = options['tests'].to_list
    #  options['loadpath'] = options['loadpath'].to_list
    #  options['exclude']  = options['exclude'].to_list
    #  options['require']  = options['require'].to_list
    #
    #  return options
    #end


  public

    # Run unit tests. Unlike test-solo and test-cross this loads
    # all tests and runs them together in a single process.
    #
    # Note that this shells out to the testrb program.
    #
    # TODO: Generate a test log entry?
    #
    def runtests
      tests    = self.tests
      loadpath = self.loadpath
      requires = self.requires
      live     = self.live
      exclude  = self.exclude

      #log      = options['log'] != false
      #logfile  = File.join('log', apply_naming_policy('test', 'log'))

      # what about arguments for selecting specific tests?
      #tests = EVN['TESTS'] if ENV['TESTS']

      #unless live
      #  loadpath.each do |lp|
      #    $LOAD_PATH.unshift(File.expand_path(lp))
      #  end
      #end

      if File.exist?('test/suite.rb')
        files = 'test/suite.rb'
      else
        files = multiglob_r(*tests)
      end

      if files.empty?
        status "WARNING: NO TESTS DEFINED!"
        return
      end

      # TODO: Use a subdirectory for log. Also html or xml format possible?

      filelist = files.select{|file| !File.directory?(file) }.join(' ')
      logfile  = project.log + 'testrb.log'

      # TODO: Does tee work on Windows?

      if live
        command = %[testrb #{filelist} 2>&1 | tee -a #{logfile}]
      else
        command = %[testrb -I#{loadpath.join(':')} #{filelist} 2>&1 | tee -a #{logfile}]
      end

      success = sh(command) #, :show=>true) #show?

      abort "Tests failed." unless success

      #if log && !trial?
      #  command = %[testrb -I#{loadpath} #{filelist} > #{logfile} 2>&1]  # /dev/null 2>&1
      #  system command
      #  puts "Updated #{logfile}"
      #end
    end

  end

end

=begin
    # Load each test independently to ensure there are no
    # require dependency issues. This is actually a bit redundant
    # as test-solo will also cover these results. So we may deprecate
    # this in the future. This does not generate a test log entry.

    def test_load(options=nil)
      options = test_configuration(options)

      tests    = options['tests']
      loadpath = options['loadpath']
      requires = options['requires']
      live     = options['live']
      exclude  = options['exclude']

      files = multiglob_r(*tests) - multiglob_r(*exclude)

      return puts("No tests.") if files.empty?

      max   = files.collect{ |f| f.size }.max
      list  = []

      files.each do |f|
        next unless File.file?(f)
        if r = system("ruby -I#{loadpath.join(':')} #{f} > /dev/null 2>&1")
          puts "%-#{max}s  [PASS]" % [f]  #if verbose?
        else
          puts "%-#{max}s  [FAIL]" % [f]  #if verbose?
          list << f
        end
      end

      puts "  #{list.size} Load Failures"

      if verbose?
        unless list.empty?
          puts "\n-- Load Failures --\n"
          list.each do |f|
            print "* "
            system "ruby -I#{loadpath} #{f} 2>&1"
            #puts
          end
          puts
        end
      end
    end
=end

