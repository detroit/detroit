require 'reap/service'
require 'facets/progressbar' # TODO: maybe add to ratch?

module Reap

  # = TestUnit Isolated Service Base Class
  #
  # This provides a common base class for TestUnitSolo and TestUnitCross.
  #
  class TestUnitIsoService < Service

    # File glob pattern of tests to run.
    attr_accessor :tests

    # Tests to specially exclude.
    attr_accessor :exclude

    # Add these folders to the $LOAD_PATH.
    attr_accessor :loadpath

    # Libs to require when running tests.
    attr_accessor :requires

    # Test against live install (i.e. Don't use loadpath option)
    attr_accessor :live

    private

    #
    def initialize_defaults
      @loadpath = metadata.loadpath
      @tests    = "test/**/test_*"
      @exclude  = []
      @reqiures = []
      @live     = false
    end

    # Collect test configuation.

    def test_configuration(options=nil)
      #options = configure_options(options, 'test')
      #options['loadpath'] ||= metadata.loadpath

      options['tests']    ||= self.tests
      options['loadpath'] ||= self.loadpath
      options['requires'] ||= self.requires
      options['live']     ||= self.live
      options['exclude']  ||= self.exclude

      #options['tests']    = options['tests'].to_list
      options['loadpath'] = options['loadpath'].to_list
      options['exclude']  = options['exclude'].to_list
      options['require']  = options['require'].to_list

      return options
    end

    # Runs the list of test calls passed to it.
    # This is used by #test_solo and #test_cross.

    def test_loop_runner(testruns)
      width = testruns.collect{ |tr| tr['display'].size }.max

      testruns = if trace?
        test_loop_runner_trace(testruns)
      elsif verbose?
        test_loop_runner_verbose(testruns)
      else
        test_loop_runner_progress(testruns)
      end

      tally = test_tally(testruns)

      report = ""
      report << "\n%-#{width}s       %10s %10s %10s %10s" % [ 'TEST FILE', '  TESTS   ', 'ASSERTIONS', ' FAILURES ', '  ERRORS   ' ]
      report << "\n"

      testruns.each do |testrun|
        count = testrun['count']
        pass = (count[2] == 0 and count[3] == 0)

        report << "%-#{width}s  " % [testrun['display']]
        report << "%10s %10s %10s %10s" % count
        report << " " * 8
        report << (pass ? "[PASS]" : "[FAIL]")
        report << "\n"
      end

      report << "%-#{width}s  " % "TOTAL"
      report << "%10s %10s %10s %10s" % tally

      #puts("\n%i tests, %i assertions, %i failures, %i errors\n\n" % tally)

      report << "\n\n"

      fails = []
      
      fails = testruns.select do |testrun|
        count = testrun['count']
        count[2] != 0 or count[3] != 0
      end

      if tally[2] != 0 or tally[3] != 0
        unless fails.empty? # or verbose?
          report << "-- Failures and Errors --\n\n"
          fails.uniq.each do |testrun|
            report << testrun['result']
          end
          report << "\n"
        end
      end

      return report
    end

    #

    def test_loop_runner_verbose(testruns)
      testruns.each do |testrun|
        result = `#{testrun['command']}`
        count  = test_parse_result(result)
        testrun['count']  = count
        testrun['result'] = result

        puts "\n" * 3; puts result
      end
      puts "\n" * 3

      return testruns
    end

    #

    def test_loop_runner_progress(testruns)
      pbar = Console::ProgressBar.new( 'Testing', testruns.size )
      pbar.inc
      testruns.each do |testrun|
        pbar.inc

        result = `#{testrun['command']}`
        count  = test_parse_result(result)
        testrun['count']  = count
        testrun['result'] = result
      end
      pbar.finish

      return testruns
    end

    #

    def test_loop_runner_trace(testruns)
      width = testruns.collect{ |tr| tr['display'].size }.max

      testruns.each do |testrun|
        print "%-#{width}s  " % [testrun['display']]

        result = `#{testrun['command']}`
        count = test_parse_result(result)
        testrun['count']  = count
        testrun['result'] = result

        pass = (count[2] == 0 and count[3] == 0)
        puts(pass ? "[PASS]" : "[FAIL]")
      end

      return testruns
    end

    #

    def test_tally(testruns)
      counts = testruns.collect{ |tr| tr['count'] }
      tally  = [0,0,0,0]
      counts.each do |count|
        4.times{ |i| tally[i] += count[i] }
      end
      return tally
    end

    #

    def test_parse_result(result)
      if md = /(\d+) tests, (\d+) assertions, (\d+) failures, (\d+) errors/.match(result)
        count = md[1..4].collect{|q| q.to_i}
      else       
        count = [1, 0, 0, 1]  # SHOULD NEVER HAPPEN
      end
      return count
    end

  end

  # = TestUnit Solo Service
  #
  # TODO: If Tim Pease accepts the solo and cross runners for turn then
  #       create a separate turn service.
  #
  class TestUnitSolo < TestUnitIsoService

    pipeline :main, :test => :validate

    available do |project|
      !Dir['test/*.rb'].empty?
      false # only available if explicitly defined in service config
    end

    # Run unit-tests. Each test is run in a separate interpretor
    # to prevent script clash. This makes for a more robust test
    # facility and prevents potential conflicts between test scripts.
    #
    #   tests     Test files (eg. test/tc_**/*.rb) [test/**/*]
    #   loadpath  Directories to include in load path [lib].
    #   require   List of files to require prior to running tests.
    #   live      Deactive use of local libs and test against install.
    #
    def test(options=nil)
      options = test_configuration(options)

      tests    = options['tests']
      loadpath = options['loadpath']
      requires = options['requires']
      live     = options['live']
      exclude  = options['exclude']

      loadpath = loadpath.to_list

      files = multiglob_r(*tests) - multiglob_r(*exclude)

      return puts("No tests.") if files.empty?

      paths = loadpath.collect{ |d| File.join(d, '**/*') }

      if !log('testunit.log').out_of_date?(*paths) && !force?
        return io.puts("Testing is current (testunit.log).")
      end

      files = files.select{ |f| File.extname(f) == '.rb' and File.file?(f) }
      width = files.collect{ |f| f.size }.max

      cmd   = %[ruby -I#{loadpath.join(':')} %s]
      dis   = "%-#{width}s"

      testruns = files.collect do |file|
        { 'files'   => file,
          'command' => cmd % file,
          'display' => dis % file
        }
      end

      report = test_loop_runner(testruns)

      puts report

      text = "= Solo Test @ #{Time.now}\n"
      text << report
      text << "\n"

      log('testunit.log').append(text)
    end

  end

  # = TestUnit Cross Service
  #
  # TODO: If Tim Pease accepts the solo and cross runners for turn then
  #       create a separate turn service.
  #
  class TestUnitCross < TestUnitIsoService

    pipeline :main, :test => :validate

    available do |project|
      !Dir['test/*.rb'].empty?
      false # only available if explicitly defined in service config
    end

    # Run cross comparison testing.
    #
    # This tool runs unit tests in pairs to make sure there is cross
    # library compatibility. Each pari is run in a separate interpretor
    # to prevent script clash. This makes for a more robust test
    # facility and prevents potential conflicts between test scripts.
    #
    #   tests     Test files (eg. test/tc_**/*.rb) [test/**/*]
    #   loadpath  Directories to include in load path.
    #   require   List of files to require prior to running tests.
    #   live      Deactive use of local libs and test against install.

    def test_cross(options=nil)
      options = test_configuration(options)

      tests    = options['tests']
      loadpath = options['loadpath']
      requires = options['requires']
      live     = options['live']
      exclude  = options['exclude']

      files = multiglob_r(*tests) - multiglob_r(exclude)

      return puts("No tests.") if files.empty?

      files = files.select{ |f| File.extname(f) == '.rb' and File.file?(f) }
      width = files.collect{ |f| f.size }.max
      pairs = files.inject([]){ |m, f| files.collect{ |g| m << [f,g] }; m }

      #project.call(:make) if project.compiles?

      cmd   = %[ruby -I#{loadpath.join(':')} -e"load('./%s'); load('%s')"]
      dis   = "%-#{width}s %-#{width}s"

      testruns = pairs.collect do |pair|
        { 'file'    => pair,
          'command' => cmd % pair,
          'display' => dis % pair
        }
      end

      report = test_loop_runner(testruns)

      puts report

      text = "\n\n= Cross Test @ #{Time.now}\n"
      text << report
      text << "\n"

      log('testunit.log').append(text)
    end

  end

end

