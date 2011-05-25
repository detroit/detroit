require 'erb'

begin
  require 'parallel'
rescue LoadError
end

require 'plugin'

require 'redline/core_ext'

require 'redline/script'
require 'redline/cli'
require 'redline/io'
require 'redline/config'

require 'redline/track'
require 'redline/tracks/main'
require 'redline/tracks/site'
require 'redline/tracks/attn'

require 'redline/service'

# FIXME: Not all io output is running through the io object.

module Redline

  #
  #PLUGIN_DIRECTORY = "plugin{,s}/redline"

  # = Application
  #
  # TODO: Probably rename this class --"Application" is too generic.
  # TODO: Continue to imporve CLI layer.
  #
  class Application

    # Commandline interface controller.
    attr :cli

    # Input/Ouput controller.
    attr :io

    # Redline mater configuration.
    attr :config

    # Run context.
    attr :script

    # Actions (extracted from services).
    attr :actions

    # New Redline Application.
    def initialize(cli_options)
      @cli      = cli_options #Redline::CLI.new
      @io       = Redline::IO.new(@cli)
      @script   = Redline::Script.new(:io=>io, :cli=>cli)
      @config   = Redline::Config.new(project)

      #@services, @actions = *load_service_configuration

      load_plugins
    end

    #
    def load_plugins
      ::Plugin.find("redline/*.rb").each do |file|
      #Redline.plugins.each do |file|
        begin
          require(file)
        rescue => err
          $stderr.puts err if $DEBUG
        end
        #Redline.module_eval(File.read(file))
      end
    end

    # Multitask mode?

    def multitask?
      cli.multitask? && defined?(Parallel) #parallel?
    end

    # Parallel library installed?

    #def parallel?
    #  if @parallel.nil?
    #    begin
    #      require 'parallel'
    #      @parallel = true
    #    rescue LoadError
    #      @parallel = false
    #    end
    #  end
    #  @parallel
    #end

    # Provides access to the Project instance.

    def project
      script.project
    end

    # User-defined service defaults.

    def defaults
      config.defaults
    end

    # Generates a master configuration template.
    # This is only used for reference purposes.

    def config_template
      cfg = {}
      Redline.services.each do |srv_name, srv_class|
        attrs = srv_class.options #instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
        atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
        atcfg['service'] = srv_class.basename.downcase
        atcfg['active']  = false
        cfg[srv_name] = atcfg
      end
      cfg
    end

    # Returns an Array of actived services.

    def active_services
      @active_services ||= (
        activelist = []
        #autolist = []

        #if config.automatic?
        #  Redline.services.each do |service_name, service_class|
        #    if service_class.available?(project) &&
        #         service_class.autorun?(project) &&
        #         !config.standard.include?(service_name)
        #      autolist << service_class
        #    end
        #  end
        #end

        service_configs.each do |key, opts|
          next unless opts && opts['active'] != false

          service_name  = opts.delete('service') || key
          service_class = Redline.services[service_name.downcase]

          abort "Unkown service #{service_name}." unless service_class

          if service_class.available?(project)
            #autolist.delete(service_class) # remove class from autolist
            #opts = inject_environment(opts) # TODO: DEPRECATE
            opts = defaults[service_name.downcase].to_h.merge(opts)
            activelist << service_class.new(script, key, opts) #project,
          #else
          #  warn "Service #{service_class} is not available."
          end
        end

        ## If any autorunning services are not accounted for then add to active list.
        #autolist.each do |service_class|
        #  service_name = service_class.basename.downcase
        #  service_opts = defaults[service_name.downcase].to_h
        #  activelist << service_class.new(script, service_name, service_opts)
        #end

        # sorting here trickles down to processing
        activelist = activelist.sort_by{ |s| s.priority || 0 }
        #activelist = activelist.sort_by{ |sc, cn, key, opts| opts['priority'] || 0 }

        activelist
      )
    end

    #alias_method :services, :active_services

    #
    #def service_configuration
    #  @service_configuration ||= (
    #    services = {}
    #    service_configs.each do |classname, options|
    #      services[classname] = options
    #    end
    #    services
    #  )
    #end

    # Service configuration. These are stored in the
    # project's task/ or script/ folder as YAML files.

    def service_configs
      config.services
      #@service_configs ||= (
      #  load_service_configs(files)
      #)
    end

=begin
    #require 'facets/hashbuilder'

    # Load service configs for a select set of redline scripts/tasks.

    def load_service_configs(files)
      files = []
      if project.root.glob('Syckfile')
        files += project.root.glob('Syckfile')
      else
        files += project.task.glob('*.red')
        files += project.script.glob('*.red')
      end
      files  = files.select{ |f| File.file?(f) }

      abort "No redline services defined." if files.empty?

      srvcfg = files.inject({}) do |cfg, file|
        tmp = TMP.new(project.metadata)
        erb = ERB.new(File.read(file))
        txt = erb.result(tmp._binding).strip
        if /\A---/ =~ txt
          yml = YAML.load(txt) || {}
        else
          yml = HashBuilder.load(txt)
        end
        cfg.update(yml)
      end

      @config = Config.new(srvcfg)

      return srvcfg
    end
=end

    # setup cli
    #def cli
    #  @cli ||= (
    #    cli = script.cli
    #    Redline.tracks.each do |key, track|
    #      track.routes.each do |stops|
    #        stops.each do |stop|
    #          if key.to_sym == :main
    #            cli.usage.subcommand("#{stop}") #.desc("no help")
    #            cli.usage.subcommand("#{key}:#{stop}")
    #          else
    #            cli.usage.subcommand("#{key}:#{stop}")
    #          end
    #        end
    #      end
    #    end
    #    cli
    #  )
    #end

    # Returns a list of services to skip as specificed on the commandline.

    def skip
      @skip ||= cli.skip.to_list.map{ |s| s.downcase }
    end

    # Run individual redline scripts/tasks.

    def runscript(script, stop)
      @config.services.clear
      @config.load_redline_file(script)
      #@service_configs = load_service_configs(script)
      run(stop)
    end

    # Start the run.

    def start(argv=ARGV)
      Dir.chdir(project.root)        # change into project directory
      load_project_plugins           # load any local plugins
      cli.parse                      # parse the cli
      stop = argv.shift #cli.command  # what stop has been requested
      #help(stop) if !stop             # if none then show help and exit
      #help(cli,stop) if cli.help?    # display help message if requested
      #help(stop) if cli.options[:help]
      run(stop)
    end

    # Show commndline help and exit.
    #def help(stop)
    #  case stop
    #  when nil
    #    puts cli.usage.help #_text
    #  else
    #    puts cli.usage.subcommand(stop).help_text
    #  end
    #  exit
    #end

    # Run up to the specified +track_and_stop+.
    def run(track_and_stop)
      # tab completion -- improve this in the future.
      #if cli == '?'
      #  m, l = [], []
      #  Redline.tracks.each do |key, track|
      #     track.stop_map.keys.each do |stop|
      #       if key == :main
      #         m << "#{stop}"
      #         l << "#{key}:#{stop}"
      #       else
      #         l << "#{key}:#{stop}"
      #       end
      #     end
      #  end
      #  puts m.sort.join(" ") + l.sort.join(" ")
      #  exit
      #end

      raise "Malformed destination -- #{track_and_stop}" unless /^\w+\:{0,1}\w+$/ =~ track_and_stop

      if track_and_stop
        name, stop = track_and_stop.split(':')
        name, stop = 'main', name unless stop
      else
        name  = 'main'
        stop = nil
      end

      name  = name.to_sym
      stop = stop.to_sym if stop

      track = Redline.tracks[name]

      raise "Unknown track -- #{name}" unless track

      if stop
        system = track.route_with_stop(stop)
        raise "Unknown stop -- #{stop}" unless system
      else
        #overview
        $stderr.puts "Unknown track:stop given."
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
      io.status_header(*h)

      start_time = Time.now

      system.each do |run_stop|
        next if skip.include?("#{run_stop}")  # TODO: Should we really allow skipping stops?
        service_hooks(name, ('pre_' + run_stop.to_s).to_sym)
        service_calls(name, ('pre_' + run_stop.to_s).to_sym)
        service_calls(name, run_stop)
        service_calls(name, ('aft_' + run_stop.to_s).to_sym)
        service_hooks(name, ('aft_' + run_stop.to_s).to_sym)
        break if stop == run_stop
      end

      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless script.quiet?
    end

    # Execute service hook for given track and destination.
    #--
    # TODO: Currently only stop counts, maybe add track subdirs.
    #++
    def service_hooks(track, stop)
       dir  = project.config + "redline/hooks"
       #hook = dir + ("#{track}/#{stop}.rb".gsub('_', '-'))
       name = stop.to_s.gsub('_', '-')
       hook = dir + "#{name}.rb"
       if hook.exist?
         io.status_line("hook", name.capitalize)
         script.instance_eval(hook.read)
       end
    end

    # Make service calls.

    def service_calls(track, stop)
      prioritized_services = active_services.group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
      prioritized_services.each do |(priority, services)|
        # remove any services specified by the -s option on the comamndline.
        services = services.reject{ |srv| skip.include?(srv.key.to_s) }
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
      if srv.respond_to?("#{track}_#{stop}")
        if script.verbose?
          io.status_line("#{srv.key.to_s} (#{srv.class}##{track}_#{stop})", stop.to_s.gsub('_', '-').capitalize)
        else
          io.status_line("#{srv.key.to_s}", stop.to_s.gsub('_', '-').capitalize)
        end
        srv.__send__("#{track}_#{stop}")
      end
    end

    # Load custom plugins.
    # FIXME: how to load?

    def load_project_plugins
      #scripts = project.config_redline.glob('*.rb')
      scripts = project.plugin.glob('*.rb')
      scripts.each do |script|
        load(script.to_s)
        #  self.class.class_eval(File.read(script))
        #instance_eval(File.read(script))
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
          io.display_action(act)
        end
        puts
      end
    end

    #def lines
    #  l =[]
    #  active_services.each do |service|
    #    service.
    #  end
    #end
  end

end #module Redline
