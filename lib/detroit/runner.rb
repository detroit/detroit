#require_relative 'core_ext'
require_relative 'script'
#require_relative 'config'
require_relative 'worker'

module Detroit

  # Runner class is the main controller class for running a session
  # of Detroit.
  #
  class Runner

	  # Configuration directory name (most likely a hidden "dot" directory).
	  DIRECTORY = "detroit"

	  # File identifier used to find a project's dertoit tool config file.
	  FILE_NAME = "{assembly,toolchain}"

	  # The default assembly system to use.
	  DEFAULT_ASSEMBLY = :standard

    # Options (generally from #cli).
    attr :options

    # Create a new Detroit Application instance.
    def initialize(options)
      @options = options

      self.skip        = options[:skip]
      self.quiet       = options[:quiet]
      self.assembly    = options[:assembly]
      self.multitask   = options[:multitask]

      self.script_file = options[:script]

      @tools    = {}
      @defaults = {}

      @loaded_plugins = {}

      #load_plugins
      #load_defaults
      load_tools
    end

    # Quiet mode?
    #
    # @return [Boolean]
    def quiet?
      @quiet
    end

    # Set quiet mode.
    #
    # @return [Boolean]
    def quiet=(boolean)
      @quiet = !!boolean
    end

    # List of tool names to skip.
    def skip
      @skip
    end

    # Set skip list.
    def skip=(list)
      @skip = list.to_list.map{ |s| s.downcase }
    end

    # Name of the assembly (default is `:standard`).
    def assembly
      @assembly
    end

    # Set assembly system to use.
    def assembly=(name)
      @assembly = (name || DEFAULT_ASSEMBLY).to_sym
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

    # Find the project's detroit configuration script.
    def script_file
      @script_file ||= root.glob("{.,}#{FILE_NAME}{,.rb,.yml,.yaml}", :casefold).first
    end

    #
    def script_file=(file)
      @script_file = file
    end

    # Provides access to the Project instance via `Detroit.project` class method.
    #
    # @return [Pathname]
    def project
      @project ||= Detroit.project(root)
    end

    # Detroit configuration.
    #def config
    #  @config ||= Toolchain::Config.new(root, assembly_files)
    #end

    # The list of a project's assembly files.
    #
    # @return [Array<String>] routine files
    #attr :toolchains

    # Tool configurations from Assembly or *.assembly files.
    # 
    # @return [Hash] service settings
    attr :tools

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

    # Generates a configuration template for any particular tool.
    # This is only used for reference purposes.
    #
    def config_template(name)
      if not Detroit.tools.key?(name)
        load_plugin(name)
      end
      list = {name => Detroit.tools[name]}
      cfg = {}
      list.each do |tool_name, tool_class|
        attrs = tool_class.options #instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
        atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
        atcfg['tool']    = tool_class.basename.downcase
        atcfg['active']  = false
        cfg[tool_name] = atcfg
      end
      cfg
    end

    #
    def tool_class_options(tool_class)
    end

    # Active workers are tool instance configured in a project's assembly files
    # that do not have their active setting turned off.
    #
    # @return [Array<Worker>] Active worker instances.
    def active_workers(track=nil)
      @active_workers ||= (
        list = []

        tools.each do |key, opts|
          next unless opts
          next unless opts['active'] != false

          if opts['track']
            next unless opts['track'].include?((track || 'main').to_s)
          end

          next if skip.include?(key.to_s)

          if opts.key?('tool') && opts.key?('tooltype')
            abort "Two tool types given for `#{key}'."
          end

          # TODO: Ultimately deprecate completely.
          if opts.key?('service')
            abort "The `service` setting has been renamed. " +
                  "Use `tool` or `tooltype` for `#{key}' instead."
          end

          tool_type = (
            opts.delete('class') || 
            opts.delete('tool')  ||
            key
          ).to_s.downcase

          unless Detroit.tools.key?(tool_type)
            load_plugin(tool_type)
          end

          tool_class = Detroit.tools[tool_type]

          abort "Unknown tool `#{tool_type}'." unless tool_class

          if tool_class.available? #(project)
            #opts = inject_environment(opts) # TODO: DEPRECATE
            options = defaults[tool_type.downcase].to_h
            options = options.merge(common_tool_options)
            options = options.merge(opts)

            # tools need to know the project's root directory
            options['root'] = root

            list << Worker.new(key, tool_class, options)
          #else
          #  warn "Worker #{tool_class} is not available."
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

    # Run up to the specified track stop.
    def run(stop)
      raise "Malformed destination -- #{stop}" unless /^\w+\:{0,1}\w+$/ =~ stop

      track, stop = stop.split(':')
      track, stop = 'main', track unless stop

      track = track.to_sym
      stop  = stop.to_sym if stop

      # TODO: Using #preconfigure as part of the protocol should probably change.

      ## prime the workers (so as to fail early)
      active_workers(track).each do |w|
        w.preconfigure if w.respond_to?("preconfigure")
      end

      sys = Detroit.assemblies[assembly.to_sym]

      raise "Unknown assembly `#{assembly}'" unless sys

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
        #tool_hooks(name, ('pre_' + run_stop.to_s).to_sym)
        tool_calls(track, ('pre_' + run_stop.to_s).to_sym)
        tool_calls(track, run_stop)
        tool_calls(track, ('aft_' + run_stop.to_s).to_sym)
        #tool_hooks(name, ('aft_' + run_stop.to_s).to_sym)
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
        'trial'   => options[:trial],
        'trace'   => options[:trace],
        'quiet'   => options[:quiet],
        'force'   => options[:force],
        'verbose' => options[:verbose]
      }
    end

    # Make tool calls.
    #
    # This groups workers by priority b/c groups of the same priority can be run
    # in parallel if the multitask option is on.
    #
    def tool_calls(track, stop)
      prioritized_workers = active_workers(track).group_by{ |w| w.priority }.sort_by{ |k,v| k }
      prioritized_workers.each do |priority, workers|
        ## remove any workers specified by the --skip option on the comamndline
        #workers = workers.reject{ |w| skip.include?(w.key.to_s) }

        ## only servies that are on the track
        #workers = workers.select{ |w| w.tracks.nil? or w.tracks.include?(w.to_s) }

        worklist = workers.map{ |w| [w, track, stop] }

        if multitask?
          results = Parallel.in_processes(worklist.size) do |i|
            run_a_worker(*worklist[i])
          end
        else
          worklist.each do |args|
            run_a_worker(*args)
          end
        end
      end
    end

    # Invoke a worker given the worker, track and stop name.
    #
    # @todo Provide more robust options, rather than just `@destination`.
    #
    # TODO: Rename this method.
    #
    # @return [void]
    def run_a_worker(worker, track, stop)
      if target = worker.stop?(stop, @destination)
        target = stop if TrueClass === target
        label  = stop.to_s.gsub('_', '-').capitalize
        if options[:trace] #options[:verbose]
          status_line("#{worker.key.to_s} (#{worker.class}##{target})", label)
        else
          status_line("#{worker.key.to_s}", label)
        end
        worker.invoke(target, @destination)
      end
    end

	  # File glob for finding root of a project.
    #
    # @return [String]
	  def root_pattern
	    "{.index,.git,.hg,.svn,_darcs}"
	  end
 
	  # Project root directory.
    #
    # @return [Pathname]
	  def root
	    @root ||= (
	      home = File.expand_path('~')
        dir  = Dir.pwd
	      path = nil

	      while dir != home && dir != '/'
	        if Dir[root_pattern].first
	          path = dir
	          break
	        end
	        dir = File.dirname(dir)
	      end

	      Pathname.new(path || Dir.pwd)
	    )
	  end

    # Load a plugin.
    #
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

    ## Pre-load plugins using `.detroit/plugins.rb`.
    #def load_plugins
    #  if file = project.root.glob('{.,}#{DIRECTORY}/plugins{,.rb}').first
    #    require file
    #  else
    #    self.defaults = {}
    #  end
    #end

    ## Load defaults from `.detroit/defaults.yml`.
    #def load_defaults
    #  if file = project.root.glob('{.,}#{DIRECTORY}/defaults{,.yml,.yaml}').first
    #    self.defaults = YAML.load(File.new(file))
    #  else
    #    self.defaults = {}
    #  end
    #end

    #
    def load_tools
      load_script(script_file)

      #if config = eval('self', TOPLEVEL_BINDING).rc_detroit
      #  @toolchains['(rc)'] = Script.new(&config)
      #  @tools.merge!(toolchains['(rc)'].tools)
      #end

      #if config = Detroit.rc_config
      #  tc = Script.new do
      #    tools.each do |c|
      #      track(c.profile, &c)
      #    end
      #  end
      #  @toolchains['(rc)'] = tc
      #  @tools.merge!(toolchains['(rc)'].tools)
      #end
    end

    # Load the detroit script.
    def load_script(file)
      script = Script.load(File.new(file), project)
      @tools.merge!(script.tools)
    end

    #
    #def each(&block)
    #  tools.each(&block)
    #end

    #
    #def size
    #  tools.size
    #end

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

    # Print a status line, which consists of worker name on the left
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

    # Get the terminals width.
    #
    # @return [Integer]
    def screen_width
      ANSI::Terminal.terminal_width
    end

  end

end #module Detroit
