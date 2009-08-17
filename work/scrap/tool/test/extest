#!/usr/bin/env ratch

# Extract embedded tests.

# Extract unit tests. This task scans every package script
# looking for sections of the form:
#
#     =begin test
#       ...
#     =end
#
# With appropriate headers, it copies these sections to files
# in your project's test/ dir, which then can be run using the
# Ratchet test task. The exact directory layout of the files to
# be tested is reflected in the test directory. You can then
# use project.rb's test task to run the tests.
#
#     files      Files to extract ['lib/**/*.rb']
#     output     Test directory   ['test/']

main :extest do
  extract_tests # Deal with arg once rathc has better support fot it.
end

# Extract tests for scripts.

def extract_tests(files=nil)
  output = 'test/embedded'     # Don't think output should be setable.

  files  = files || 'lib/**/*.rb'
  files = 'lib/**/*.rb' if TrueClass == files
  files = [files].flatten.compact

  filelist = files.collect{ |f| Dir.glob(f) }
  filelist.flatten!
  if filelist.empty?
    puts "No scripts found from which to extract tests."
    return
  end

  mkdir_p(output) unless directory?(output)

  #vrunner = VerbosityRunner.new("Extracting", verbosity?)
  #vrunner.setup(filelist.size)

  filelist.each do |file|
    #vrunner.prepare(file)

    testing = extract_test_from_file( file )
    if testing.strip.empty?
      status = "[NONE]"
    else
      complete_test = create_test(testing, file)
      libpath = File.dirname(file)
      testfile = "test_" + File.basename(file)
      fp = File.join(output, libpath, testfile)
      unless directory?( File.dirname(fp))
        mkdir_p(File.dirname(fp))
      end
      if dryrun?
        puts "write #{fp}"
      else
        File.open(fp, "w"){ |fw| fw << complete_test }
      end
      status = "[TEST]"
    end

    #vrunner.complete(file, status)
  end

  #vrunner.finish(
  #  :normal => "#{filelist.size} files had tests extracted.",
  #  :check => false
  #)
end

private

# Extract test from a file's testing comments.

def extract_test_from_file( file )
  return nil if ! File.file?( file )
  tests = ""; inside = false
  fstr = File.read( file )
  fstr.split(/\n/).each do |l|
    if l =~ /^=begin[ ]*test/i
      tests << "\n"
      inside = true
      next
    elsif inside and l =~ /^=[ ]*end/
      inside = false
      next
    end
    if inside
      tests << l << "\n"
    end
  end
  tests
end

# Generate the test.

def create_test( testing, file )
  fp = file.split(/[\/]/)
  if fp[0] == 'lib'
    reqf = "require '#{fp[1..-1].join('/')}'"
  else
    reqf = ''
  end
  str = []
  str << "  #  _____         _"
  str << "  # |_   _|__  ___| |_"
  str << "  #   | |/ _ \\/ __| __|"
  str << "  #   | |  __/\\__ \\ |"
  str << "  #   |_|\\___||___/\\__|"
  str << "  #"
  str << "  # for #{file}"
  str << "  #"
  str << "  # Extracted #{Time.now}"
  str << "  # w/ Test Extraction Ratchet"
  str << "  #"
  str << ""
  str << " #{reqf}"
  str << ""
  str << testing
  str << "\n"
  str = str.join("\n")
  str
end
