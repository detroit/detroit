module Detroit

  #
  DEFAULT_CIRCUIT = :standard

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
      load_standard_plugins
    end

    # Load standard plugins.
    def load_standard_plugins
      #::Plugin.find("detroit/*.rb").each do |file|
      Detroit.standard_plugins.each do |file|
        begin
          require(file)
        rescue => err
          $stderr.puts err if $DEBUG
        end
      end
    end

    #
    def circuit
      options[:circuit] || DEFAULT_CIRCUIT
    end

    #
    def quiet?
      options[:quiet]
    end

    # Multitask mode?
    def multitask?
      options[:multitask] && defined?(Parallel)
    end

    # Returns a list of services to skip as specificed on the commandline.
    def skip
      @skip ||= options[:skip].to_list.map{ |s| s.downcase }
    end

    # Detroit configuration.
    def config
      @config ||= Detroit::Config.new(project)
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

    # Generates a master configuration template.
    # This is only used for reference purposes.
    def config_template
      cfg = {}
      Detroit.services.each do |srv_name, srv_class|
        attrs = srv_class.options #instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
        atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
        atcfg['service'] = srv_class.basename.downcase
        atcfg['active']  = false
        cfg[srv_name] = atcfg
      end
      cfg
    end

    # Active services are services defined in pitfiles and do not
    # have their active setting turned off.
    #
    # Returns Array of actived services.
    def active_services
      @active_services ||= (
        activelist = []

        service_configs.each do |key, opts|
          next unless opts && opts['active'] != false

          service_name  = opts.delete('service') || key
          service_class = Detroit.services[service_name.to_s.downcase]

          abort "Unknown service #{service_name}." unless service_class

          if service_class.available?(project)
            #opts = inject_environment(opts) # TODO: DEPRECATE
            options = defaults[service_name.downcase].to_h
            options = options.merge(common_tool_options)
            options = options.merge(opts)
            #activelist << service_class.new(key, options) #script,
            activelist << ServiceWrapper.new(key, service_class, options) #script,
          #else
          #  warn "Service #{service_class} is not available."
          end
        end

        # sorting here trickles down to processing later
        activelist = activelist.sort_by{ |s| s.priority || 0 }
        #activelist = activelist.sort_by{ |sc, cn, key, opts| opts['priority'] || 0 }

        activelist
      )
    end

    #alias_method :services, :active_services

    # Service configuration. These are stored in the project's Pitfile,
    # or .detroit/ or task/ folders as Ruby or YAML files.
    #
    # Returns Hash of service name and settings.
    def service_configs
      config.services
    end

    # Run individual detroit scripts/tasks.
    def runscript(script, stop)
      @config.services.clear
      @config.load_detroit_file(script)
      #@service_configs = load_service_configs(script)
      run(stop)
    end

    # Start the run.
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

      circ = Detroit.circuits[circuit]

      raise "Unkown circuit `#{circuit}'" unless circ

      track = circ.get_track(name, stop)

      #if stop
      #  system = track.route_with_stop(stop)
      #  raise "Unknown stop -- #{stop}" unless system

      if not track.include?(stop)
        #overview
        $stderr.puts "Unknown stop for track `#{name}'."
        exit 0
      end

      # prime the services (so as to fail early)
      active_services.each do |srv|
        srv.preconfigure if srv.respond_to?("preconfigure")
      end

      if multitask?
        h = ["#{project.metadata.title} v#{project.metadata.version}   [M]", "#{project.root}"]
      else
        h = ["#{project.metadata.title} v#{project.metadata.version}", "#{project.root}"]
      end
      status_header(*h)

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
      dir  = project.root.glob("{.,}detroit/hooks").first
    end

    #
    def hook_tool
      @hook_tool ||= RedTools::Tool.new(common_tool_options)
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
    def service_calls(track, stop)
      prioritized_services = active_services.group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
      prioritized_services.each do |(priority, services)|
        ## remove any services specified by the -s option on the comamndline
        services = services.reject{ |srv| skip.include?(srv.key.to_s) }
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
        if options[:verbose]
          #status_line("#{srv.key.to_s} (#{srv.class}##{track}_#{stop})", stop.to_s.gsub('_', '-').capitalize)
          status_line("#{srv.key.to_s} (#{srv.class}##{stop})", stop.to_s.gsub('_', '-').capitalize)
        else
          status_line("#{srv.key.to_s}", stop.to_s.gsub('_', '-').capitalize)
        end
        #srv.__send__("#{track}_#{stop}")
        srv.invoke(stop)
      end
    end

    # Returns a list of all terminal stops, i.e. stops at a tracks end.
    # FIXME: stop_map is not defined.
    def end_stops
      (stop_map.keys - stop_map.values).compact
    end

    # Give an overview of stops this track supports.
    # FIXME: end_stops blows up.
    def overview
      end_stops.each do |stop_name|
        action_plan(stop_name).each do |act|
          display_action(act)
        end
        puts
      end
    end

    # --- Print Methods ------------------------------------------------------

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
      if ANSI::SUPPORTED
        printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
        printline(left, right, :pad=>2, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
        printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
      else
        printline(left, right, :pad=>2, :sep=>'=')
      end
    end

    #
    def print_phase(left, right)
      if ANSI::SUPPORTED
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
