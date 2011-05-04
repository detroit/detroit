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

require 'redline/cycles'
require 'redline/cycles/main'
require 'redline/cycles/site'
require 'redline/cycles/attn'

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
        require(file)
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
        attrs = srv_class.instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
        atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
        atcfg['service'] = srv_class.basename.downcase
        atcfg['active']  = false
        cfg[srv_name] = atcfg
      end
      cfg
    end

    # Returns an array of actived services.

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
    #    Redline.lifecycles.each do |key, lifecycle|
    #      lifecycle.cycles.each do |phases|
    #        phases.each do |phase|
    #          if key.to_sym == :main
    #            cli.usage.subcommand("#{phase}") #.desc("no help")
    #            cli.usage.subcommand("#{key}:#{phase}")
    #          else
    #            cli.usage.subcommand("#{key}:#{phase}")
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

    def runscript(script, job)
      @config.services.clear
      @config.load_redline_file(script)
      #@service_configs = load_service_configs(script)
      run(job)
    end

    # Start the cycle.

    def start(argv=ARGV)
      Dir.chdir(project.root)        # change into project directory
      load_project_plugins           # load any local plugins
      cli.parse                      # parse the cli
      job = argv.shift #cli.command  # what cycle-phase has been requested
      #help(job) if !job             # if none then show help and exit
      #help(cli,job) if cli.help?    # display help message if requested
      #help(job) if cli.options[:help]
      run(job)
    end

    # Show commndline help and exit.
    #def help(job)
    #  case job
    #  when nil
    #    puts cli.usage.help #_text
    #  else
    #    puts cli.usage.subcommand(job).help_text
    #  end
    #  exit
    #end

    # Run the cycle upto the specified cycle-phase.

    def run(job)
      # tab completion -- improve this in the future.
      #if cli == '?'
      #  m, l = [], []
      #  Redline.tracks.each do |key, track|
      #     track.phasemap.keys.each do |phase|
      #       if key == :main
      #         m << "#{phase}"
      #         l << "#{key}:#{phase}"
      #       else
      #         l << "#{key}:#{phase}"
      #       end
      #     end
      #  end
      #  puts m.sort.join(" ") + l.sort.join(" ")
      #  exit
      #end

      raise "Malformed life-cycle -- #{job}" unless /^\w+\:{0,1}\w+$/ =~ job

      if job
        name, phase = job.split(':')
        name, phase = 'main', name unless phase
      else
        name  = 'main'
        phase = nil
      end

      name  = name.to_sym
      phase = phase.to_sym if phase

      lifecycle = Redline.lifecycles[name]

      raise "Unknown life-cycle -- #{name}" unless lifecycle

      if phase
        system = lifecycle.cycle_with_phase(phase)
        raise "Unknown phase -- #{phase}" unless system
      else
        #overview
        $stderr.puts "Unknown name:phase given."
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

      system.each do |run_phase|
        next if skip.include?("#{run_phase}")  # TODO: Should we really allow skipping phases?
        service_hooks(name, ('pre_' + run_phase.to_s).to_sym)
        service_calls(name, ('pre_' + run_phase.to_s).to_sym)
        service_calls(name, run_phase)
        service_calls(name, ('aft_' + run_phase.to_s).to_sym)
        service_hooks(name, ('aft_' + run_phase.to_s).to_sym)
        break if phase == run_phase
      end

      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless script.quiet?
    end

    # Execute service hook for given track and phase.
    #--
    # TODO: Currently only phase counts, maybe add track subdirs.
    #++
    def service_hooks(track, phase)
       dir  = project.config + "redline/hooks"
       #hook = dir + ("#{track}/#{phase}.rb".gsub('_', '-'))
       name = phase.to_s.gsub('_', '-')
       hook = dir + "#{name}.rb"
       if hook.exist?
         io.status_line("hook", name.capitalize)
         script.instance_eval(hook.read)
       end
    end

    # Make service calls.

    def service_calls(track, phase)
      prioritized_services = active_services.group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
      prioritized_services.each do |(priority, services)|
        # remove any services specified by the -s option on the comamndline.
        services = services.reject{ |srv| skip.include?(srv.key.to_s) }
        tasklist = services.map{ |srv| [srv, track, phase] }
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

    # Run a service given the service, track name and phase name.

    def run_a_service(srv, track, phase)
      # run if the service supports the track and phase.
      if srv.respond_to?("#{track}_#{phase}")
        if script.verbose?
          io.status_line("#{srv.key.to_s} (#{srv.class}##{track}_#{phase})", phase.to_s.gsub('_', '-').capitalize)
        else
          io.status_line("#{srv.key.to_s}", phase.to_s.gsub('_', '-').capitalize)
        end
        srv.__send__("#{track}_#{phase}")
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

    # Returns a list of all the phases that terminate a pipleline execution.
    # FIXME: phase_map is not defined.

    def end_phases
      (phase_map.keys - phase_map.values).compact
    end

    # Give an overview of phases this track supports.
    # FIXME: end_phases blows up.

    def overview
      end_phases.each do |phase_name|
        action_plan(phase_name).each do |act|
          io.display_action(act)
        end
        puts
      end
    end

  end

end #module Redline
