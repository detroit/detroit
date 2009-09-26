require 'erb'

begin
  require 'parallel'
  $REAP_PARALLEL = true
rescue LoadError
  $REAP_PARALLEL = false
end

require 'syckle/script'
#require 'syckle/project'
require 'syckle/cli'
require 'syckle/io'
require 'syckle/config'

require 'syckle/cycles'
require 'syckle/cycles/main'
require 'syckle/cycles/site'
require 'syckle/cycles/attn'

require 'syckle/service'
require 'syckle/plugins'

#require 'facets/consoleutils'
#require 'facets/ansicode'

# TODO: Not all io output is running through the io object.

module Syckle

  # = Application
  #
  # TODO: This class can be simplified.
  # TODO: Probably rename this class.
  # TODO: Need to add a CLI layer separate from the rest.
  #
  class Application

    #CONFIG_FILE      = 'syckle'
    #PLUGIN_DIRECTORY = 'plugin'

    # Commandline interface controller.
    attr :cli

    # Input/Ouput controller
    attr :io

    # Syckle mater configuration.
    attr :config

    # Run context
    attr :script

    # Actions (from services).
    attr :actions

    # New Syckle Application.
    def initialize(cli_options)
      @cli    = cli_options #Syckle::CLI.new
      @config = Syckle::Config.new
      @io     = Syckle::IO.new(@cli)
      @script = Syckle::Script.new(:io=>io, :cli=>cli)
      #@services, @actions = *load_service_configuration
      load_plugins
    end

    def load_plugins
      Syckle.plugins.each do |file|
        require(file)
      end
    end

    def multitask?
      $REAP_PARALLEL && cli.multitask?
    end

    def project
      script.project
    end

    # Generates a master configuration template.
    # This is only used for reference.
    def config_template
      cfg = {}
      Syckle.services.each do |srv_name, srv_class|
        attrs = srv_class.instance_methods.select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }
        atcfg = attrs.inject({}){ |h, m| h[m.to_s.chomp('=')] = nil; h }
        atcfg['service'] = srv_class.basename.downcase
        atcfg['active']  = false
        cfg[srv_name] = atcfg
      end
      cfg
    end

    # Returns an array of actived services.
    #
    def active_services
      @active_services ||= (
        a = []

        #configs = service_configs #uration
        # only services configs that have options and are active
        #s = s.select{ |key, opts| opts && opts['active'] != false }

        autolist = []

        if config.automatic?
          Syckle.services.each do |service_name, service_class|
            if service_class.available?(project) && 
               service_class.autorun?(project) && 
               !config.auto_omit.include?(service_name)
              autolist << service_class
            end
          end
        end

        service_configs.each do |key, opts|
          next unless opts && opts['active'] != false

          service_name  = opts.delete('service') || key
          service_class = Syckle.services[service_name.downcase]

          abort "Unkown service #{service_name}." unless service_class

          opts = inject_environment(opts) # TODO: REMOVE

          if service_class.available?(project)
            autolist.delete(service_class) # remove class from autolist
            a << service_class.new(script, key, opts) #project,
          end
        end

        # If any autorunning services are not accounted for then add to active list.
        autolist.each do |service_class|
          service_name = service_class.basename.downcase
          a << service_class.new(script, service_name) #, {})
        end

        # sorting here trickles down to processing
        a = a.sort_by{ |s| s.priority || 0 }

        #a = a.sort_by{ |sc, cn, key, opts| opts['priority'] || 0 }
        a
      )
    end

    #alias_method :services, :available_services

    # Returns a list of activated services.
    #def active_services
    #  available_services.map do |srvClass, className, key, options|
    #    srvClass.new(script, key, options) #project,
    #  end
    #end

    # This substitutes environment vairables in for
    # service options if they are given in the form
    # of +ENV[NAME]+.
    def inject_environment(options)
      opts = {}
      options.each do |k,v|
        if String === v && md = /^ENV\[(.*?)\]/.match(v)
          opts[k] = ENV[md[1]]
        else
          opts[k] = v
        end
      end
      opts
    end

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
    #
    def service_configs
      @service_configs ||= (
        files = []
        files += project.task.glob('*.syckle')
        files += project.script.glob('*.syckle')
        files = files.select{ |f| File.file?(f) }
        load_service_configs(files)
      )
    end

    # Load service configs for a select set of syckle scripts/tasks.
    def load_service_configs(files)
      abort "No syckle services defined." if files.empty?
      files.inject({}) do |cfg, file|
        tmp = TMP.new(project.metadata)
        erb = ERB.new(File.read(file))
        txt = erb.result(tmp._binding)
        yml = YAML.load(txt) || {}
        cfg.update(yml)
      end
    end

    # setup cli
    #def cli
    #  @cli ||= (
    #    cli = script.cli
    #    Syckle.lifecycles.each do |key, lifecycle|
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

    # Run individual syckle scripts/tasks.
    #
    def runscript(script, job)
      @service_configs = load_service_configs(script)
      run(job)
    end

    # Start the cycle.
    def start
      Dir.chdir(project.root)        # change into project directory
      load_project_plugins           # load any local plugins
      cli.parse                      # parse the cli
      job = ARGV.shift #cli.command  # what cycle-phase has been requested
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
      # Improve this in the future.
      #if cli == '?'
      #  m, l = [], []
      #  Syckle.pipelines.each do |key, pipe|
      #     pipe.phasemap.keys.each do |phase|
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

      if job
        name, phase = job.split(':')
        name, phase = 'main', name unless phase
      else
        name  = 'main'
        phase = nil
      end

      name  = name.to_sym
      phase = phase.to_sym if phase

      lifecycle = Syckle.lifecycles[name]

      raise "Unknown life-cycle -- #{name}" unless lifecycle

      if phase
        system = lifecycle.cycle_with_phase(phase)
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
        service_calls(name, ('pre_' + run_phase.to_s).to_sym)
        service_calls(name, run_phase)
        service_calls(name, ('aft_' + run_phase.to_s).to_sym)
        break if phase == run_phase
      end

      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless script.quiet?
    end

    # Make service calls.
    def service_calls(pipe, phase)
      prioritized_services = active_services.group_by{ |srv| srv.priority }.sort_by{ |k,v| k }
      prioritized_services.each do |(priority, services)|
        # remove any services specified by the -s option on the comamndline.
        services = services.reject{ |srv| skip.include?(srv.key.to_s) }
        tasklist = services.map{ |srv| [srv, pipe, phase] }
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

    # Run a service given the service, pipe name and phase name.
    def run_a_service(srv, pipe, phase)
      # run if the service supports the pipe and phase.
      if srv.respond_to?("#{pipe}_#{phase}")
        if script.verbose?
          io.status_line("#{srv.key.to_s} (#{srv.class}##{pipe}_#{phase})", phase.to_s.capitalize)
        else
          io.status_line("#{srv.key.to_s}", phase.to_s.capitalize)
        end
        srv.__send__("#{pipe}_#{phase}")
      end
    end

    # Load custom plugins.
    # FIXME: how to load?
    def load_project_plugins
      #scripts = project.config_syckle.glob('*.rb')
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

    # Give an overview of phases this pipeline supports.
    # FIXME: end_phases blows up.
    def overview
      end_phases.each do |phase_name|
        action_plan(phase_name).each do |act|
          io.display_action(act)
        end
        puts
      end
    end

    # = Configuration Template Binding
    #
    # This class is used to render service congifs via erb.
    #
    class TMP
      instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }
      attr :metadata
      def initialize(metadata)
        @metadata = metadata
      end
      def _binding
        binding
      end
      def method_missing(s)
        metadata.send(s)
      end
    end

  end

end#module Syckle






=begin
#      phase_actions = {}
#      pipeline.each{ |phase| phase_actions[phase] = [] }

#      services.each do |label, service|
#        phases = service.class.service_actions[chosen_pipeline]
#        phases.each do |phase, actions|
#          actions.each do |action|
#            phase_actions[phase] ||= []
#            phase_actions[phase] << [label, service, action]
#          end
#        end
#      end

      if choosen_phase
        phases = pipeline[0..pipeline.index(choosen_phase.to_sym)]
        #max = phases.collect{ |phase| phase_actions.keys.collect{ |k| phase.to_s.size + k.to_s.size }}.flatten.max

        phases.each do |phase|
          #project.current_phase = phase.to_s.capitalize
          #project.status_line('', phase.to_s.capitalize, ' ') unless phase_actions[phase].empty?
          #puts "\n= #{phase.to_s.capitalize}\n"
          if phase == :document or phase == :analyize
            phase_actions[phase].each do |label, service, action|
              #project.current_service = label.to_s.capitalize
              if fork?
                status_line(label.capitalize, phase.to_s.capitalize, '-')
                pid = fork do  # FIXME: This won't work on windows.
                  silently{ service.send(action) }
                end
                status("Process Forked -> #{pid}")
              else
                #pid = Process.pid
                status_line(label.capitalize, phase.to_s.capitalize, '-')
                service.send(action)
              end
              #Process.detach(pid)
              #sleep 1
            end
          else
            phase_actions[phase].each do |label, service, action|
              #project.current_service = label.to_s.capitalize
              status_line(label.capitalize, phase.to_s.capitalize, '-')
              service.send(action)
            end
          end
        end

        stop_time = Time.now

        puts "\nFinished in #{stop_time - start_time} seconds." unless project.quiet?
      else
        phases = service.class.service_actions[chosen_pipeline]

        phases.each do |phase, actions|
          puts "\n[#{phase}]"
          actions.each do |label, service, action|
            puts "syckle #{phase} #{label} #{action}"
          end
        end
      end
=end

