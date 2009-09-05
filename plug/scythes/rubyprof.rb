module Syckles

  # = RubyProf Profiling Plugin
  #
  # This is a Reap service plugin for ruby-proof command line tool.
  #
  class RubyProf < Service

    cycle :main, :analyize
    cycle :main, :reset
    cycle :main, :clean

    # Default script files to run via ruby-prof.
    DEFAULT_SCRIPTS = ['test/**/test_*.rb', 'test/**/*_test.rb']

    # Pattern of script files to run for coverage check. Usually
    # these are your test files, but they can be any ruby scripts.
    # By default this is includes .rb file in the test/ directory
    # whose name begins with test_ or ends with _test.
    attr :scripts

    # Output directory. This defaults to an rubyprof/ folder in the
    # the project's log directory.
    attr :output

    # Additional commandline options string passed to ruby-prof.
    attr :options

    #
    def initialize_defaults
      @output  = project.log + 'rubyprof'
      @scripts = DEFAULT_SCRIPTS
    end

    # Shell out to ruby-prof.
    #
    # TODO: Need to create an index.html file to link to all the others.
    #
    def analyize
      files = scripts.map{ |s| Dir[s] }.flatten
      # create output directory if needed
      mkdir_p(output) unless File.exist?(output)
      # if nothing is out-of-date
      if outofdate?(output, *files) or force?
        # make a profile for each script
        files.each do |file|
          fname = output + "#{File.basename(file)}.html"
          if outofdate?(output, file) or force?
            sh "ruby-prof #{options} -m 1 -p graph_html -f #{fname} #{file}"
          end
        end
        report "ruby-prof updated (at #{output.sub(Dir.pwd,'')})"
      else
        report "ruby-prof is current (at #{output.sub(Dir.pwd,'')})"
      end
    end

    # Reset output directory, ie. set mtime to oldest date possible.
    def reset
      if File.directory?(output)
        File.utime(0,0,output)
        report "reset #{output}" #unless dryrun?
      end
    end

    # Remove output directory and it's contents.
    def clean
      if File.directory?(output)
        rm_r(output)
        status "removed #{output}" #unless dryrun?
      end
    end

    # Require RCov library.
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
