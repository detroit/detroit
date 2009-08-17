# TITLE:
#
#   Test
#
# TODO:
#   - Needs to be made DRY.
#   - Perhaps simplifiy this, making it more like the load test.
#     And simply collect that parse the output of each test.

require 'facets/hash/rekey'
require 'facets/string/tabs'
require 'facets/progressbar'

module Reap

  class Manager

    private

    # Collect test configuation.

    def test_configuration(options=nil)
      options = configure_options(options, 'test')

      libs  = options['loadpath'] || metadata.loadpath || 'lib'
      tests = options['tests']    || 'test/**/{test,tc}_*.rb'
      live  = options['live']
      reqs  = options['require']

      libs  = [libs].flatten
      tests = [tests].flatten

      return tests, libs, reqs, live
    end

    public

    # Basic unit test run.

    def test_unit(options={})
      tests, libs, reqs, live = *test_configuration(options)

      unless live
        libs.each do |lp|
          $LOAD_PATH.unshift(File.expand_path(lp))
        end
      end

#       if find = argv[0]
#         unless file?(find)
#           find = File.join(find, '**', 'test_*.rb')
#         end
#       else
#         find = 'test/**/test_*.rb'
#       end

      files = multiglob_r(*tests)

      if files.empty?
        puts "No tests."
      else
        files.each do |file|
          next if dir?(file)
          load file
        end
      end
    end

    # Load each test independently to ensure there are no
    # require dependency issues.

    def test_load(options=nil)
      tests, libs, reqs, live = *test_configuration(options)

      #unless Array===libpath
      #  libpath = libpath.split(/[:;]/)
      #end

      files = multiglob_r(*tests) #- multiglob_r(ignore)

      return puts("No tests.") if files.empty?

      max   = files.collect{ |f| f.size }.max
      list  = []

      files.each do |f|
        next unless File.file?(f)
        #if not system "ruby -c -Ibin:lib:test #{s} &> /dev/null" then
        if r = system("ruby -I#{libs} #{f} > /dev/null 2>&1")
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
            system "ruby -I#{libs} #{f} 2>&1"
            #puts
          end
          puts
        end
      end
    end

    # Run unit-tests. Each test is run in a separate interpretor
    # to prevent script clash. This makes for a more robust test
    # facility and prevents potential conflicts between test scripts.
    #
    #   tests     Test files (eg. test/tc_**/*.rb) [test/**/*]
    #   libs      Directories to include in load path.
    #             ('./lib' is always included)
    #   live      Deactive use of local libs and test against install.
    #   reqs      List of files to require prior to running tests.
    #   extract   Extract embedded tests first? [false]
    #
    # To isolate tests this tool marshals test results across a
    # stdout->stdin shell pipe. This prevents interfence of one
    # script's tests on another. But consequently it is not always
    # possible to send debug info to stdout in the tests themselves
    # (eg. #p and #puts).

    def test_solo(options={})
#       config = configuration['test'] || {}
#       options = config.merge(options)
#       options = options.to_ostruct
#
#       live     = options.live
#       libpath  = options.loadpath
#       tests    = options.tests
#       reqs     = options.requires
#
#       loadpath ||= "lib"
#       tests    ||= 'test/**/test_*.rb'
#
#       #tests   = config['files'] || 'test/unit/**/test_*.rb'
#       #libs    = libpath #config['libpath']
#       #reqs    = requires #config['require']
#       #live    = config['live']
#       #extract = config['extract']
#
#       tests = [tests].flatten
#       libs  = [libpath].flatten

      #files = [ @files ].flatten
      #extract_tests if extract

      tests, libs, reqs, live = *test_configuration(options)

      require 'test/unit/ui/testrunnermediator' #require 'test/unit'
      ::Test::Unit.run = true # Don't autorun tests!

      results  = TestResults.new #(style)

      # get test files
      test_libs  = libs.join(':')
      test_files = Dir.multiglob_r(*tests)
      if test_files.empty?
        puts "No tests."
        return
      end

      # run tests

      if trace?
        pbar = nil
        size = test_files.collect{|f| f.size}.max + 5
        dots = '.' * size
      else
        pbar = Console::ProgressBar.new( 'Testing', test_files.size )
        pbar.inc
      end

      test_files.each do |test_file|
        pbar.inc if pbar
        if ! File.file?(test_file)
          next #r = nil
        else
          unless pbar
            print test_file + dots[test_file.size..-1]
            $stdout.flush
          end
          r = test_fork( test_file, :libs=>libs, :reqs=>reqs, :live=>live )
          unless pbar
            puts r.passed? ? "[PASS]" : "[FAIL]"
          end
        end
        results << r
      end

      pbar.finish if pbar

      # display results
      puts results

      fails, errrs = results.failure_count, results.error_count
      #CHECKLIST << :test if fails > 0
      #CHECKLIST << :test if errrs > 0
      return (fails + errrs > 0)
    end

    # run cross comparison tests
    #
    # This tool runs unit tests in pairs to make
    # sure there is cross library compatibility.
    #
    # Run unit-tests. Each test is run in a separate interpretor
    # to prevent script clash. This makes for a more robust test
    # facility and prevents potential conflicts between test scripts.
    #
    #   tests     Test files (eg. test/tc_**/*.rb) [test/**/*]
    #   libs      Directories to include in load path.
    #             ('./lib' is always included)
    #   live      Deactive use of local libs and test against install.
    #   reqs      List of files to require prior to running tests.
    #   extract   Extract embedded tests first? [false]
    #
    # To isolate tests this tool marshals test results across a
    # stdout->stdin shell pipe. This prevents interfence of one
    # script's tests on another. But consequently it is not always
    # possible to send debug info to stdout in the tests themselves
    # (eg. #p and #puts).

    def test_cross(options={})
#       config = configuration['test'] || {}
#       options = config.merge(options)
#       options = options.to_ostruct
#
#       live     = options.live
#       libpath  = options.loadpath
#       tests    = options.tests
#       reqs     = options.requires
#
#       loadpath ||= "lib"
#       tests    ||= 'test/**/test_*.rb'
#
#       #tests   = config['tests'] || 'test/**/test_*.rb'
#       #reqs    = requires #config['require']
#       #libs    = config['libpath']
#       #live    = config['live']
#       #extract = info['extract']
#
#       tests = [tests].flatten
#       libs  = [libpath].flatten

      tests, libs, reqs, live = *test_configuration(options)

      require 'test/unit/ui/testrunnermediator' #require 'test/unit'
      ::Test::Unit.run = true # Don't autorun tests!

      results  = TestResults.new #(style)

      # get test files
      test_libs  = libs.join(':')
      test_files = Dir.multiglob( *tests )
      if test_files.empty?
        puts "No tests."
        return
      end

      # run tests

      if trace?
        pbar = nil
        size = test_files.collect{|f| f.size}.max * 2 + 5
        dots = '.' * size
      else
        pbar = Console::ProgressBar.new('Testing', test_files.size ** 2)
        pbar.inc
      end

      test_files.each do |test_file|
        next unless File.file?(test_file)

        test_files.each do |test_file_x|
          next unless File.file?(test_file_x)
          next if test_file == test_file_x

          pbar.inc if pbar
          unless pbar
            out = test_file +' : ' + test_file_x
            print out + dots[out.size..-1]
            $stdout.flush
          end

          r = fork_crosstest( test_file, test_file_x, :libs=>libs, :reqs=>reqs, :live=>live )

          unless pbar
            puts r.passed? ? "[PASS]" : "[FAIL]"
          end

          results << r
        end
      end

      pbar.finish if pbar

      # display results
      puts results

      fails, errrs = results.failure_count, results.error_count
      #CHECKLIST << :test if fails > 0
      #CHECKLIST << :test if errrs > 0
      return (fails + errrs > 0)
    end

    private

    # Run a test in a separate process.
    #
    # Currently send program output to null device.
    # Could send to a logger in future version.
    #
    # Key parameters are libs, reqs, live.

    def fork_crosstest( file, xfile, keys )
      keys = keys.rekey(:to_s)

      libs = keys['lib'] || []
      reqs = keys['req'] || []
      live = keys['live']

      src = ''

      unless live
        l = File.join( Dir.pwd, 'lib' )
        if File.directory?( l )
          src << %{$:.unshift('#{l}')\n}
        end
        libs.each { |r| src << %{$:.unshift('#{r}')\n} }
      end

      src << %{
        #require 'test/unit'
        require 'test/unit/collector'
        require 'test/unit/collector/objectspace'
        require 'test/unit/ui/testrunnermediator'
      }

      reqs.each do |fix|
        src << %Q{
          require '#{fix}'
        }
      end

      src << %{
        def warn(*null); end  # silence warnings

        output = STDOUT.dup
        STDOUT.reopen( PLATFORM =~ /mswin/ ? "NUL" : "/dev/null" )

        load('#{file}')
        load('#{xfile}')

        tests = Test::Unit::Collector::ObjectSpace.new.collect
        runner = Test::Unit::UI::TestRunnerMediator.new( tests )
        result = runner.run_suite

        begin
          marshalled = Marshal.dump(result)
        rescue TypeError => e
          $stderr << "MARSHAL ERROR\n"
          $stderr << "TEST: #{file}\n"
          $stderr << "XTEST: #{xfile}\n"
          $stderr << "DATA:" << result.inspect
          exit -1
        end
        output << marshalled

        STDOUT.reopen(output)
        output.close
      }

      result = IO.popen("ruby","w+") do |ruby|
        ruby.puts src
        ruby.close_write
        ruby.read
      end

      begin
        marsh = Marshal.load(result)
      rescue ArgumentError
        $stderr << "\nCannot load marshalled test data.\n"
        $stderr << result << "\n"
        exit -1
      end

      return marsh
    end

    # Run a test in a separate process.
    #
    # Currently send program output to null device.
    # Could send to a logger in future version.
    #
    # Key parameters are libs, reqs, live.

    def test_fork( file, keys )
      keys = keys.rekey(:to_s)

      libs = keys['lib'] || []
      reqs = keys['req'] || []
      live = keys['live']

      src = ''

      unless live
        l = File.join( Dir.pwd, 'lib' )
        if File.directory?( l )
          src << %{$:.unshift('#{l}')\n}
        end
        libs.each { |r| src << %{$:.unshift('#{r}')\n} }
      end

      src << %{
        #require 'test/unit'
        require 'test/unit/collector'
        require 'test/unit/collector/objectspace'
        require 'test/unit/ui/testrunnermediator'
      }

      reqs.each do |fix|
        src << %Q{
          require '#{fix}'
        }
      end

      src << %{
        def warn(*null); end  # silence warnings

        output = STDOUT.dup
        STDOUT.reopen( PLATFORM =~ /mswin/ ? "NUL" : "/dev/null" )

        load('#{file}')

        tests = Test::Unit::Collector::ObjectSpace.new.collect
        runner = Test::Unit::UI::TestRunnerMediator.new( tests )
        result = runner.run_suite

        begin
          marshalled = Marshal.dump(result)
        rescue TypeError => e
          $stderr << "MARSHAL ERROR\n"
          $stderr << "TEST: #{file}\n"
          $stderr << "DATA:" << result.inspect
          exit -1
        end
        output << marshalled

        STDOUT.reopen(output)
        output.close
      }

      result = IO.popen("ruby","w+") do |ruby|
        ruby.puts src
        ruby.close_write
        ruby.read
      end

      begin
        marsh = Marshal.load(result)
      rescue ArgumentError
        $stderr << "\nCannot load marshalled test data.\n"
        $stderr << result << "\n"
        exit -1
      end

      return marsh
    end

  end

  # = Test Results
  #
  # Support class for collecting test results.

  class TestResults #:nodoc:
    attr_reader :assertion_count,
                :run_count,
                :failure_count,
                :error_count

    attr_accessor :style

    def initialize( style=nil )
      @style = style

      @results = []

      @assertion_count = 0
      @run_count = 0
      @failure_count = 0
      @error_count = 0
    end

    # Add a result to the results collection.

    def <<( result )
      @results << result

      @assertion_count += result.assertion_count
      @run_count += result.run_count
      @failure_count += result.failure_count
      @error_count += result.error_count
    end

    #

    def errors
      errors = []
      @results.each do |r|
        unless r.passed?
          errors << r.instance_variable_get('@errors')
        end
      end
      errors.reject! { |e| e == [] }
      errors
    end

    #

    def failures
      failures = []
      @results.each do |r|
        unless r.passed?
          failures << r.instance_variable_get('@failures')
        end
      end
      failures.reject! { |e| e == [] }
      failures
    end

    # Output format for test results.

    def to_s
      return @results.to_s if style == 'pease'

      s = []
      # Display failures
      unless failures.empty?
        s << ''
        s << "FAILURES:"
        failures.reverse.each do |fails|
          fails.reverse.each do |failure|
            #puts
            s << %{  - test      : #{failure.test_name}}
            s << %{    location  : #{failure.location}}
            if failure.message.index("\n")
              s << %{    message   : >}
              s << failure.message.tabto(6)
            else
              s << %{    message   : #{failure.message}}
            end
          end
        end
      end

      # Display errors
      unless errors.empty?
        s << ''
        s << "ERRORS:"
        errors.reverse.each do |errs|
          errs.reverse.each do |err|
            s << ''
            s << %{  - test      : #{err.test_name}}
            s << %{    message   : #{err.exception.message}}
            s << %{    backtrace :}
            err.exception.backtrace[0...-1].each { |bt| s << %Q{      - #{bt}} }
          end
        end
      end

      # Display final results
      s << ''
      s << "Summary:"
      s << "  Tests      : #{@run_count}"
      s << "  Assertions : #{@assertion_count}"
      s << "  Failures   : #{@failure_count}"
      s << "  Errors     : #{@error_count}"
      s << ''
      s << ''

      return s.join("\n")
    end

    # Delegate missing call to the results array.

    def method_missing(*a,&b)
      @results.send(*a,&b)
    end
  end

end
