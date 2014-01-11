#require_relative 'core_ext'
require_relative 'script'
require_relative 'config'
require_relative 'service'

module Detroit

  module Assembly

    # Configuration directory name (most likely a hidden "dot" directory).
    DIRECTORY = "detroit"

    # File identifier used to find a project's Assembly file(s).
    FILE_EXTENSION = "assembly"

    # The default assembly system to use.
    DEFAULT_TOOLCHAIN = :standard

    # Assembly::Runner class is the main controller class for running
    # a session of Detroit.
    #
    class Runner

      # Options (generally from #cli).
      attr :options

      # Create a new Detroit Application instance.
      def initialize(options)
        @options = options

        self.skip       = options[:skip]
        self.quiet      = options[:quiet]
        self.toolchain  = options[:toolchain]
        self.multitask  = options[:multitask]
        self.assembly_files = options[:assemblies]

        @assemblies = {}
        @services   = {}
        @defaults   = {}

        @loaded_plugins = {}

        load_up
      end

      #
      def load_up
        load_plugins
        load_defaults
        load_assemblies
      end

      # Quiet mode?
      def quiet?
        @quiet
      end

      # Set quiet mode.
      def quiet=(boolean)
        @quiet = !!boolean
      end

      # List of service names to skip.
      def skip
        @skip
      end

      # Set skip list.
      def skip=(list)
        @skip = list.to_list.map{ |s| s.downcase }
      end

      # Name of the toolchain.
      def toolchain
        @toolchain
      end

      # Set assembly system to use.
      def toolchain=(name)
        @toolchain = (name || DEFAULT_TOOLCHAIN)
      end

      # Multitask mode?
      def multitask?
        @multitask      
      end

      # Set multi-task mode.
      def multitask=(boolean)
        if boolean && !defined?(Parallel)
          puts "Parallel gem must be installed to multitask."
          @multitask = false
        else
          @multitask = boolean
        end
      end

      # List of assembly files to use.
      def assembly_files
        @assembly_files
      end

      #
      def assembly_files=(files)
        @assembly_files = files
      end

      # Provides access to the Project instance via `Detroit.project` class method.
      def project
        @project ||= Detroit.project(root)
      end

      # Detroit configuration.
      #def config
      #  @config ||= Assembly::Config.new(root, assembly_files)
      #end

      # The list of a project's assembly files.
      #
      # @return [Array<String>] routine files
      attr :assemblies

      # Service configurations from Assembly or *.assembly files.
      # 
      # @return [Hash] service settings
      attr :services

      # Custom service defaults. This is a mapping of service names to
      # default settings. Very useful for when using the same
      # service more than once.
      #
      # @return [Hash] default settings
      attr :defaults

      # Set defaults.
      def defaults=(hash)
        @defaults = hash.to_h
      end

      # Display detailed help for a given tool.
      #
      # @return [void]
      def display_help(name)
        if not Detroit.tools.key?(name)
          load_plugin(name)
        end
        tool = Detroit.tools[name]
        if tool.const_defined?(:MANPAGE)
          man_page = tool.const_get(:MANPAGE)
          Kernel.system "man #{man_page}"
        else
          puts "No detailed help available for `#{name}'."
        end
      end

      # Generates a configuration template for particular tool.
      # This is only used for reference purposes.
      def config_template(name)
        if not Detroit.tools.key?(name)
          load_plugin(name)
        end
        list = {name => Detroit.tools[name]}
        cfg = {}
        list.each do |srv_name, srv_class|
          attrs = srv_class.options #instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
          atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
          atcfg['service'] = srv_class.basename.downcase
          atcfg['active']  = false
          cfg[srv_name] = atcfg
        end
        cfg
      end

      #
      def tool_class_options(tool_class)

      end

      # Active services are services defined in assembly files and do not
      # have their active setting turned off.
      #
      # Returns Array of active services.
      def active_services(group=nil)
        @active_services ||= (
          list = []

          services.each do |key, opts|
            next unless opts
            next unless opts['active'] != false

            if opts['group']
              next unless opts['group'].include?((group || 'main').to_s)
            end

            next if skip.include?(key.to_s)

            tool_name = (opts.delete('tool')    ||
                         opts.delete('service') || key).to_s.downcase

            unless Detroit.tools.key?(tool_name)
              load_plugin(tool_name)
            end

            tool_class = Detroit.tools[tool_name]

            abort "Unknown tool `#{tool_name}'." unless tool_class

            if tool_class.available? #(project)
              #opts = inject_environment(opts) # TODO: DEPRECATE
              options = defaults[tool_name.downcase].to_h
              options = options.merge(common_tool_options)
              options = options.merge(opts)

              list << Service.new(key, tool_class, options) #script,
            #else
            #  warn "Service #{tool_class} is not available."
            end
          end

          # sorting here trickles down to processing later
          #list = list.sort_by{ |s| s.priority || 0 }

          list
        )
      end

      # Change direectory to project root and run.
      def start(stop)
        Dir.chdir(project.root) do       # change into project directory
          run(stop)
        end
      end

      # Run up to the specified group and stop.
      def run(stop)
        raise "Malformed destination -- #{stop}" unless /^\w+\:{0,1}\w+$/ =~ stop

        group, stop = stop.split(':')
        group, stop = 'main', group unless stop

        group = group.to_sym
        stop  = stop.to_sym if stop

        # TODO: Using #preconfigure as part of the protocol should probably change.

        # prime the services (so as to fail early)
        active_services(group).each do |srv|
          srv.preconfigure if srv.respond_to?("preconfigure")
        end

        sys = Detroit.toolchains[toolchain.to_sym]

        raise "Unknown toolchain `#{toolchain}'" unless sys

        # Lookup chain by stop name.
        chain = sys.find(stop)

        #if stop
        #  system = track.route_with_stop(stop)
        #  raise "Unknown stop -- #{stop}" unless system

        unless chain
          #overview
          $stderr.puts "Unknown stop `#{stop}'."
          exit 0
        end

        @destination = stop

        status_header(*header_message)

        start_time = Time.now

        chain.each do |run_stop|
          next if skip.include?("#{run_stop}")  # TODO: Should we really allow skipping stops?
          #service_hooks(name, ('pre_' + run_stop.to_s).to_sym)
          service_calls(group, ('pre_' + run_stop.to_s).to_sym)
          service_calls(group, run_stop)
          service_calls(group, ('aft_' + run_stop.to_s).to_sym)
          #service_hooks(name, ('aft_' + run_stop.to_s).to_sym)
          break if stop == run_stop
        end

        stop_time = Time.now
        puts "\nFinished in #{stop_time - start_time} seconds." unless quiet?
      end

=begin
    # TODO: Deprecate service hooks?

    #
    # Execute service hook for given track and destination.
    #
    # @todo Currently only stop counts, maybe add track subdirs.
    #
    def service_hooks(track, stop)
       #hook = dir + ("#{track}/#{stop}.rb".gsub('_', '-'))
       dir  = hook_directory
       return unless dir
       name = stop.to_s.gsub('_', '-')
       hook = dir + "#{name}.rb"
       if hook.exist?
         status_line("hook", name.capitalize)
         hook_tool.instance_eval(hook.read)
       end
    end

    # Returns a project's Detroit hooks directory.
    def hook_directory
      project.root.glob("{.,}detroit/hooks").first
    end

    #
    def hook_tool
      @hook_tool ||= Tool.new(common_tool_options)
    end
=end

      # TODO: Do we need verbose?
      def common_tool_options
        {
          'project' => project,
          'trial'   => options[:trial],
          'trace'   => options[:trace],
          'quiet'   => options[:quiet],
          'force'   => options[:force],
          'verbose' => options[:verbose]
        }
      end

      # Make service calls.
      #
      # This groups services by priority b/c groups of the same priority can be run
      # in parallel if the multitask option is on.
      def service_calls(group, stop)
        prioritized_services = active_services(group).group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
        prioritized_services.each do |priority, services|
          ## remove any services specified by the --skip option on the comamndline
          #services = services.reject{ |srv| skip.include?(srv.key.to_s) }

          ## only servies that are on the track
          #services = services.select{ |srv| srv.tracks.nil? or srv.tracks.include?(track.to_s) }

          tasklist = services.map{ |srv| [srv, group, stop] }
          if multitask?
            results = Parallel.in_processes(tasklist.size) do |i|
              run_a_service(*tasklist[i])
            end
          else
            tasklist.each do |args|
              run_a_service(*args)
            end
          end
        end
      end

      #
      # Run a service given the service, track and stop name.
      #
      def run_a_service(srv, group, stop)
        if srv.stop?(stop, @destination)
          if options[:trace] #options[:verbose]
            status_line("#{srv.key.to_s} (#{srv.class}##{stop})", stop.to_s.gsub('_', '-').capitalize)
          else
            status_line("#{srv.key.to_s}", stop.to_s.gsub('_', '-').capitalize)
          end
          srv.invoke(stop, @destination)
        end
      end

      # --- Print Methods -------------------------------------------------------

      def header_message
        if multitask?
          ["#{project.metadata.title} v#{project.metadata.version}   [M]", "#{project.root}"]
        else
          ["#{project.metadata.title} v#{project.metadata.version}", "#{project.root}"]
        end
      end

      # Print a status header, which consists of project name and version on the
      # left and stop location on the right.
      #
      def status_header(left, right='')
        left, right = left.to_s, right.to_s
        #left.color  = 'blue'
        #right.color = 'magenta'
        unless quiet?
          puts
          print_header(left, right)
          #puts "=" * io.screen_width
        end
      end

      # Print a status line, which consists of service name on the left
      # and stop name on the right.
      #
      def status_line(left, right='')
        left, right = left.to_s, right.to_s
        #left.color  = 'blue'
        #right.color = 'magenta'
        unless quiet?
          puts
          #puts "-" * io.screen_width
          print_phase(left, right)
          #puts "-" * io.screen_width
          #puts
        end
      end

      #
      def display_action(action_item)
        phase, service, action, parameters = *action_item
        puts "  %-10s %-10s %-10s" % [phase.to_s.capitalize, service.service_title, action]
        #status_line(service.service_title, phase.to_s.capitalize)
      end

      #
      def print_header(left, right)
        if $ansi #ANSI::SUPPORTED
          printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
          printline(left, right, :pad=>2, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
          printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
        else
          printline(left, right, :pad=>2, :sep=>'=')
        end
      end

      #
      def print_phase(left, right)
        if $ansi #ANSI::SUPPORTED
          printline(left, right, :pad=>2, :sep=>' ', :style=>[:on_white, :black, :bold], :left=>[:bold], :right=>[:bold])
        else
          printline(left, right, :pad=>2, :sep=>'-')
        end
      end

      #
      def printline(left, right='', options={})
        return if quiet?

        separator = options[:seperator] || options[:sep] || ' '
        padding   = options[:padding]   || options[:pad] || 0

        left, right = left.to_s, right.to_s

        left_size  = left.size
        right_size = right.size

        #left  = colorize(left)
        #right = colorize(right)

        l = padding
        r = -(right_size + padding)

        style  = options[:style] || []
        lstyle = options[:left]  || []
        rstyle = options[:right] || []

        left  = lstyle.inject(left) { |s, c| ansize(s, c) }
        right = rstyle.inject(right){ |s, c| ansize(s, c) }

        line = separator * screen_width
        line[l, left_size]  = left  if left_size != 0
        line[r, right_size] = right if right_size != 0

        line = style.inject(line){ |s, c| ansize(s, c) }

        puts line + ansize('', :clear)
      end

      #
      def ansize(text, code)
        #return text unless text.color
        if RUBY_PLATFORM =~ /win/
          text.to_s
        else
          ANSI::Code.send(code.to_sym) + text
        end
      end

      #
      def screen_width
        ANSI::Terminal.terminal_width
      end

      # TODO: Lookup project root.
      def root
        Pathname.new(Dir.pwd)
      end

      # -----------------------------------------------------------------------

      # Load a plugin.
      def load_plugin(name)
        @loaded_plugins[name] ||= (
          begin
            require "detroit-#{name}"
          rescue LoadError => e
            $stderr.puts "ERROR: #{e.message.capitalize}"
            $stderr.puts "       Perhaps `gem install detroit-#{name}`?"
            exit -1
          end
          name # true ?
        )
      end

      # Pre-load plugins using `.detroit/plugins.rb`.
      def load_plugins
        if file = project.root.glob('{.,}#{DIRECTORY}/plugins{,.rb}').first
          require file
        else
          self.defaults = {}
        end
      end

      # Load defaults from `.detroit/defaults.yml`.
      def load_defaults
        if file = project.root.glob('{.,}#{DIRECTORY}/defaults{,.yml,.yaml}').first
          self.defaults = YAML.load(File.new(file))
        else
          self.defaults = {}
        end
      end

      #
      def load_assemblies
        assembly_filenames.each do |file|
          load_assembly_file(file)
        end

        #if config = eval('self', TOPLEVEL_BINDING).rc_detroit
        #  @assemblies['(rc)'] = Assembly.new(&config)
        #  @services.merge!(assemblies['(rc)'].services)
        #end

        #if config = Detroit.rc_config
        #  assembly = Assembly.new do
        #    services.each do |c|
        #      track(c.profile, &c)
        #    end
        #  end
        #  @assemblies['(rc)'] = assembly
        #  @services.merge!(assemblies['(rc)'].services)
        #end
      end

      # Load assembly file.
      #
      def load_assembly_file(file)
        @assemblies[file] = Assembly::Script.load(File.new(file), project)
        @services.merge!(assemblies[file].services)
      end

      # If a `Assembly` or `.assembly` file exists, then it is returned. Otherwise
      # all `*.assembly` files are loaded. To load `*.assembly` files from another
      # directory add the directory to config options file.
      def assembly_filenames
        @assembly_filenames ||= (
          files = []
          ## match 'Assembly' or '.assembly' file
          files = project.root.glob("{,.,*.}#{FILE_EXTENSION}{,.rb,.yml,.yaml}", :casefold)
          ## only files
          files = files.select{ |f| File.file?(f) }
          ## 
          if files.empty?
            ## match '.detroit/*.assembly' or 'detroit/*.assembly'
            files += project.root.glob("{,.}#{DIRECTORY}/*.#{FILE_EXTENSION}", :casefold)
            ## match 'task/*.assembly' (OLD SCHOOL)
            files += project.root.glob("{task,tasks}/*.#{FILE_EXTENSION}", :casefold)
            ## only files
            files = files.select{ |f| File.file?(f) }
          end
          files
        )
      end

      #
      #def each(&block)
      #  services.each(&block)
      #end

      #
      #def size
      #  services.size
      #end

=begin
    # If using a `Routine` file and want to import antoher file then use
    # `import:` entry.
    def load_detroit_file(file)
      #@dir = File.dirname(file)

      assemblies[file] = 

      # TODO: can we just read the first line of the file and go from there?
      #text = File.read(file).strip

      ## if yaml vs. ruby file
      #if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
      #  #data = parse_detroit_file_yaml(text, file)
      #  YAML.load(text)
      #else
      #  data = parse_detroit_file_ruby(text, file)
      #end    

      ## extract defaults
      #if defaults = data.delete('defaults')
      #  @defaults.merge!(defaults)
      #end

      ## import other files
      #if import = data.delete('import')
      #  [import].flatten.each do |glob|
      #    routine(glob)
      #  end
      #end

      ## require plugins
      #if plugins = data.delete('plugins')
      #  [plugins].flatten.each do |file|
      #    require file
      #  end
      #end

      #@services.update(data)
    end
=end

      ## Parse a YAML-based routine.
      #def parse_detroit_file_yaml(text, file)
      #  YAMLParser.parse(self, text, file)
      #end

      ## Parse a Ruby-based routine.
      #def parse_detroit_file_ruby(text, file)
      #  RubyParser.parse(self, text, file)
      #end

      ## TODO: Should the +dir+ be relative to the file or root?
      #def routine(glob)
      #  pattern = File.join(@dir, glob)
      #  Dir[pattern].each{ |f| load_detroit_file(f) }
      #end

    end

  end

end #module Detroit
