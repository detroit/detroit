module Detroit

  module Toolchain

    #
    def self.cli(argv=ARGV)
      CLI.execute(argv)
    end

    ##
    # The CLI class.
    class CLI

      # Location of standard plugins.
      #PLUGIN_DIRECTORY = File.dirname(__FILE__) + '/plugins'

      # Returns Array of standard plugin file names.
      #def standard_plugins
      #  Dir[PLUGIN_DIRECTORY + '/*.rb']
      #end

      # Universal acccess to the current project.
      #
      # TODO: Is Control#project being used?
      #def project
      #  @project ||= POM::Project.find
      #end

      #
      # argv - Command line arguments.
      #
      def self.execute(argv=ARGV)
        new.execute(*argv)
      end

      # Run the command line interface.
      def initialize
        @options = {
          :toolchains => [], 
          :assembly   => nil,
          :trace      => nil, 
          :trial      => nil,
          :debug      => nil,
          :quiet      => nil,
          :verbose    => nil,
          :force      => nil,
          :multitask  => nil,
          :skip       => []
        }
      end

      #
      def execute(*argv)
        #if /\.assembly$/ =~ argv[0]
        #  job = argv[1]
        #  begin
        #    application(cli_options).runscript(argv[0], job)
        #  rescue => error
        #    $stderr.puts error.message
        #    exit -1
        #  end
        #else

        option_parser.parse!(argv)

        if $DEBUG
          application(options).start(*argv)
        else
          begin
            application(options).start(*argv)
          rescue => error
            $stderr.puts error.message
            exit -1
          end
        end
      end

      # Returns Runner instance given options.
      def application(options={})
        Runner.new(options)
      end

      # Command line options.
      def options
        @options
      end

      #
      def toolchains
        @options[:toolchains]
      end

      #
      def skip
        @options[:skip]
      end

      #
      def multitask
        @options[:multitask]
      end

      #
      def multitask=(boolean)
        @options[:multitask] = !!boolean
      end

      #
      def assembly
        @options[:assembly]
      end

      #
      def assembly=(name)
        @options[:assembly] = name.to_sym
      end

      #
      def force
        @options[:force]
      end

      #
      def force=(boolean)
        @options[:force] = !!boolean
      end

      #
      def trial
        @options[:trial]
      end

      #
      def trial=(boolean)
        @options[:trial] = !!boolean
      end

      #
      def trace
        @options[:trace]
      end

      #
      def trace=(boolean)
        @options[:trace] = !!boolean
      end

      #
      def quiet
        @options[:quiet]
      end

      #
      def quiet=(boolean)
        @options[:quiet] = !!boolean
      end

      #
      def verbose
        @options[:quiet]
      end

      #
      def verbose=(boolean)
        @options[:verbose] = !!boolean
      end

      # Create command line option parser.
      def option_parser
        usage_banner
        option_multitask
        option_assembly
        option_toolchain
        option_skip
        option_trial
        option_trace
        option_loadpath
        option_force
        option_verbose
        option_quiet
        option_config
        option_debug
        option_warn
        option_help
        usage
      end

      # Cached instance of OptionParser.
      #
      # @return [OptionParser]
      def usage
        @usage ||= OptionParser.new
      end

      # @return [String]
      def usage_banner
        usage.banner = "Usage: detroit [<track>:]<stop> [options]"
      end

      # @return [void]
      def option_multitask
        usage.on('-m', '--multitask', "Run work elements in parallel.") do
          self.multitask = true
        end
      end

      # @return [void]
      def option_assembly
        usage.on('-a', '--assembly=NAME', "Select assembly. Default is `standard'.") do |a|
          self.assembly = a
        end
      end

      # @return [void]
      def option_toolchain
        usage.on('-t', '--toolchain [FILE]', 'Use specific toolchain file(s).') do |file|
          self.toolchains << file
        end
      end

      # @return [void]
      def option_skip
        usage.on('-S', '--skip [NAME]', 'Skip a tool instance.') do |skip|
          self.skip << skip
        end
      end

      # @return [void]
      def option_trial
        usage.on('--trial', "Run in TRIAL mode (no disk writes).") do
          #$TRIAL = true
          self.trial =  true
        end
      end

      # @return [void]
      def option_trace
        usage.on('--trace', "Run in TRACE mode.") do
          #$TRACE = true
          self.trace = true
        end
      end

      # @todo Do we really need verbose?
      #
      # @return [void]
      def option_verbose
        usage.on('--verbose', "Provide extra output.") do
          self.verbose = true
        end
      end

      # @return [void]
      def option_quiet
        usage.on('-q', '--quiet', "Run silently.") do
          self.quiet = true
        end
      end

      # @return [void]
      def option_force
        usage.on('-F', '--force', "Force operations.") do
          self.force = true
        end
      end

      # @return [void]
      def option_loadpath
        usage.on('-I=PATH', "Add directory to $LOAD_PATH") do |dirs|
          dirs.to_list.each do |dir|
            $LOAD_PATH.unshift(dir)
          end
        end
      end

      # @return [void]
      def option_debug
        usage.on('--debug', "Run with $DEBUG set to true.") do
          $DEBUG = true
        end
      end

      # @return [void]
      def option_warn
        usage.on('--warn', "Run with $VERBOSE set to true.") do
          $VERBOSE = true  # wish this were called $WARN
        end
      end

      # @return [void]
      def option_help
        usage.on_tail('--help [TOOL]', "Display this help message.") do |tool|
          if tool
            application.display_help(tool)
          else
            puts usage
          end
          exit
        end
      end

      #
      def option_config
        usage.on_tail('-c', '--config TOOL', "Produce a configuration template.") do |tool|
          puts application.config_template(tool).to_yaml
          exit
        end
      end

    end

  end

end
