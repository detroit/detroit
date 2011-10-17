module Detroit

  # The default assembly system to use.
  DEFAULT_ASSEMBLY_SYSTEM = :standard

  # Application class is the main controller class for running
  # a session of Detroit.
  #--
  # TODO: Rename Application to `Session`?
  #++
  class Application

    # Options (generally from #cli).
    attr :options

    # Create a new Detroit Application instance.
    def initialize(options)
      @options = options
      #load_standard_plugins

      self.skip       = options[:skip]
      self.quiet      = options[:quiet]
      self.system     = options[:system]
      self.multitask  = options[:multitask]
      self.assemblies = options[:assemblies]
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

    # The selected assembly system.
    def system
      @system
    end

    # Set assembly system to use.
    def system=(name)
      @system = (name || DEFAULT_ASSEMBLY_SYSTEM)
    end

    # Alias for #system.
    alias :assembly_system :system

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
    def assemblies
      @assemblies
    end

    #
    def assemblies=(files)
      @assemblies = files
    end

    # Detroit configuration.
    def config
      @config ||= Detroit::Config.new(assemblies)
    end

    # Provides access to the Project instance via `Detroit.project` class method.
    def project
      @project ||= POM::Project.find
    end

    # User-defined service defaults.
    #
    # Returns Hash of service defaults.
    def defaults
      config.defaults
    end

#    # Load standard plugins.
#    def load_standard_plugins
#      #::Plugin.find("detroit/*.rb").each do |file|
#      Detroit.standard_plugins.each do |file|
#        begin
#          require(file)
#        rescue => err
#          $stderr.puts err if $DEBUG
#        end
#      end
#    end

    # Display detailed help for a given tool.
    def display_help(name)
      if not Detroit.tools.key?(name)
        config.load_plugin(name)
      end
      tool = Detroit.tools[name]
      if tool.respond_to?(:man_page)
        Kernel.system "man #{tool.man_page}"
      else
        puts "Sorry, no detailed help available for `#{name}'."
      end
    end

    # Generates a configuration template for particular tool.
    # This is only used for reference purposes.
    def config_template(name)
      if not Detroit.tools.key?(name)
        config.load_plugin(name)
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

    # TODO: Setup all services, then ween out inactive ones?
    #def services
    #end

    # Active services are services defined in assembly files and do not
    # have their active setting turned off.
    #
    # Returns Array of active services.
    def active_services
      @active_services ||= (
        list = []

        config.each do |key, opts|
          next unless opts
          next unless opts['active'] != false
          next if skip.include?(key.to_s)

          tool_name = (
            opts.delete('tool')    ||
            opts.delete('service') ||
            key
          ).to_s.downcase

          unless Detroit.tools.key?(tool_name)
            config.load_plugin(tool_name)
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

    # Run up to the specified +track_and_stop+.
    def run(track_and_stop)
      raise "Malformed destination -- #{track_and_stop}" unless /^\w+\:{0,1}\w+$/ =~ track_and_stop

      if track_and_stop
        name, stop = track_and_stop.split(':')
        name, stop = 'main', name unless stop
      else
        name = 'main'
        stop = nil
      end

      name = name.to_sym
      stop = stop.to_sym if stop

      assm = Detroit.assembly_systems[system]

      raise "Unkown assembly system `#{system}'" unless assm

      track = assm.get_track(name, stop)

      #if stop
      #  system = track.route_with_stop(stop)
      #  raise "Unknown stop -- #{stop}" unless system

      if not track.include?(stop)
        #overview
        $stderr.puts "Unknown stop for track `#{name}'."
        exit 0
      end

      @destination = stop

      # prime the services (so as to fail early)
      active_services.each do |srv|
        srv.preconfigure if srv.respond_to?("preconfigure")
      end

      status_header(*header_message)

      start_time = Time.now

      track.each do |run_stop|
        next if skip.include?("#{run_stop}")  # TODO: Should we really allow skipping stops?
        service_hooks(name, ('pre_' + run_stop.to_s).to_sym)
        service_calls(name, ('pre_' + run_stop.to_s).to_sym)
        service_calls(name, run_stop)
        service_calls(name, ('aft_' + run_stop.to_s).to_sym)
        service_hooks(name, ('aft_' + run_stop.to_s).to_sym)
        break if stop == run_stop
      end

      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless quiet?
    end

    # Execute service hook for given track and destination.
    #--
    # TODO: Deprecate service hooks?
    #
    # TODO: Currently only stop counts, maybe add track subdirs.
    #++
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
    def service_calls(track, stop)
      prioritized_services = active_services.group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
      prioritized_services.each do |priority, services|
        ## remove any services specified by the --skip option on the comamndline
        #services = services.reject{ |srv| skip.include?(srv.key.to_s) }
        ## only servies that are on the track
        services = services.select{ |srv| srv.tracks.nil? or srv.tracks.include?(track.to_s) }

        tasklist = services.map{ |srv| [srv, track, stop] }
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

    # Run a service given the service, track name and stop name.
    def run_a_service(srv, track, stop)
      # run if the service supports the track and stop.
      #if srv.respond_to?("#{track}_#{stop}")
      if srv.stop?(stop)
        if options[:trace] #options[:verbose]
          #status_line("#{srv.key.to_s} (#{srv.class}##{track}_#{stop})", stop.to_s.gsub('_', '-').capitalize)
          status_line("#{srv.key.to_s} (#{srv.class}##{stop})", stop.to_s.gsub('_', '-').capitalize)
        else
          status_line("#{srv.key.to_s}", stop.to_s.gsub('_', '-').capitalize)
        end
        #srv.__send__("#{track}_#{stop}")
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

  end

end #module Detroit
