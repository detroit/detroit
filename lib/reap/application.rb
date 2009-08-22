require 'erb'

begin
  require 'parallel'
  $REAP_PARALLEL = true
rescue LoadError
  $REAP_PARALLEL = false
end

require 'reap/domain'
#require 'reap/project'
require 'reap/cli'
require 'reap/io'

require 'reap/pipeline'
require 'reap/pipelines/main'
require 'reap/pipelines/site'
require 'reap/pipelines/attn'

require 'reap/plugins'

#require 'facets/consoleutils'
#require 'facets/ansicode'

# TODO: Not all io output is running through the io object.

module Reap

  # = Application
  #
  # TODO: This class can be simplified.
  # TODO: Probably rename this class.
  # TODO: Need to add a CLI layer separate from the rest.
  #
  class Application

    #CONFIG_FILE      = 'reap'
    #PLUGIN_DIRECTORY = 'plugin'

    # Run Domain
    attr :domain

    # Actions (from services).
    attr :actions

    # New Reap Application.
    def initialize(options={})
      cli = Reap::CLI.new
      io  = Reap::IO.new(cli)
      @domain = Domain.new(:io=>io, :cli=>cli)
      #@services, @actions = *load_service_configuration
    end

    def multitask?
      $REAP_PARALLEL && cli.multitask?
    end

    def io
      domain.io
    end

    def project
      domain.project
    end

    # Returns an array of service class, class name, service key, options
    def available_services
      @available_services ||= (
        a = []
        s = service_configuration
        # only services configs that have options and are active
        s = s.select{ |key, opts| opts && opts['active'] != false }
        s.each do |(service_key, options)|
          #next unless options
          #next if options['active'] == false
          classname = options.delete('service')
          abort "No service for #{service_key}." unless classname
          #
          service_class = Reap.services[classname.downcase]
          abort "Unkown service #{classname}." unless service_class
          #
          options = inject_environment(options)
          #
          if service_class.available?(project)
            a << [service_class, classname, service_key, options]
          end
        end
        # sorting here trickles down to processing
        a = a.sort_by{ |sc, cn, key, opts| opts['priority'] || 0 }
        a
      )
    end

    #alias_method :services, :available_services

    # Returns a list of activated services.
    def active_services
      available_services.map do |srvClass, className, key, options|
        srvClass.new(domain, key, options) #project,
      end
    end

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
    def service_configuration
      @service_configuration ||= (
        services = {}
        service_configs.each do |classname, options|
          services[classname] = options
        end
        services
      )
    end

    # Load service configuration. These are stored in the
    # project's reap/ folder as YAML configuration files.
    #
    # TODO: Should an .yaml extension be required?
    def service_configs
      @service_configs ||= (
        data = {}
        files  = project.task.glob('*.reap')
        files += project.config.glob('*.reap')

        # DEPRECATE
        files += (project.config + 'reap').glob('*')

        files = files.select{ |f| File.file?(f) }

        abort "No reap services defined." if files.empty?

        files.each do |file|
          # run through erb
          env  = TemplateEnv.new(project.metadata)
          erb  = ERB.new(File.read(file))
          txt  = erb.result(env.get_binding)

          conf = YAML.load(txt)
          data.update(conf || {})

          #begin
          #rescue ArgumentError => e
          #  puts "Error loading config -- #{file}"
          #  puts e
          #end
        end
        data
      )
    end

    # setup cli
    def cli
      @cli ||= (
        cli = domain.cli
        Reap.pipelines.each do |key, pipe|
          pipe.phasemap.keys.each do |phase|
            if key == :main
              cli.usage.subcommand("#{phase}") #.desc("no help")
              cli.usage.subcommand("#{key}:#{phase}")
            else
              cli.usage.subcommand("#{key}:#{phase}")
            end
          end
        end
        cli
      )
    end

    # Returns a list of services to skip as specificed on the commandline.
    def skip
      @skip ||= cli.skip.to_list.map{ |s| s.downcase }
    end

    # Run the pipeline.
    def start
      # change into project directory
      Dir.chdir(project.root)
      # load any plugins
      load_plugins
      # parse the cli
      cli.parse
      # what job has been requested (ie. pipe & phase )
      job = cli.command
      # if no job then show help and exit
      unless job
        puts cli.help #_text
        exit
      end
      # display help message if requested
      if cli.options[:help] #cli.help?
        if job
          puts cli.usage.subcommand(job).help_text
        else
          puts cli.usage.help_text
        end
        exit
      end

      # Improve this in the future.
      #if cli == '?'
      #  m, l = [], []
      #  Reap.pipelines.each do |key, pipe|
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
        pipe, phase = job.split(':')
        pipe, phase = 'main', pipe unless phase
      else
        pipe = 'main'
        phase = nil
      end

      pipe  = pipe.to_sym
      phase = phase.to_sym if phase

      pipeline = Reap.pipelines[pipe]

      raise "Unknown pipeline -- #{pipe}" unless pipeline

      if phase
        system = pipeline.system_with_phase(phase)
      else
        overview
        exit 0
      end

      # prime the services (so as to fail early)
      #active_services
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

      system.each do |run_phase|
        next if skip.include?("#{run_phase}")  # TODO: Should we really allow skipping phases?
        service_calls(pipe, run_phase)
        break if phase == run_phase
      end

      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless domain.quiet?
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
        if domain.verbose?
          status_line("#{srv.key.to_s} (#{srv.class}##{pipe}_#{phase})", phase.to_s.capitalize)
        else
          status_line("#{srv.key.to_s}", phase.to_s.capitalize)
        end
        srv.send("#{pipe}_#{phase}")
      end
    end

    # Load custom plugins.
    # FIXME: how to load?
    def load_plugins
      #scripts = project.config_reap.glob('*.rb')
      scripts = project.plugin.glob('*.rb')
      scripts.each do |script|
        load(script.to_s)
        #  self.class.class_eval(File.read(script))
        #instance_eval(File.read(script))
      end
    end

    # Returns a list of all the phases that terminate a pipleline execution.
    def end_phases
      (phase_map.keys - phase_map.values).compact
    end

    # Give an overview of phases this pipeline supports.
    # FIXME
    def overview
      end_phases.each do |phase_name|
        action_plan(phase_name).each do |act|
          display(act)
        end
        puts
      end
    end

    #
    def display(action_item)
      phase, service, action, parameters = *action_item
      puts "  %-10s %-10s %-10s" % [phase.to_s.capitalize, service.service_title, action]
      #status_line(service.service_title, phase.to_s.capitalize)
    end

    #
    #
    def status_header(left, right='')
      left, right = left.to_s, right.to_s

      #left.color  = 'blue'
      #right.color = 'magenta'

      unless domain.quiet?
        puts
        io.print_header(left, right)
        #puts "=" * io.screen_width
      end
    end

    #
    #
    def status_line(left, right='')
      left, right = left.to_s, right.to_s

      #left.color  = 'blue'
      #right.color = 'magenta'

      unless domain.quiet?
        puts
        #puts "-" * io.screen_width
        io.print_phase(left, right)
        #puts "-" * io.screen_width
        #puts
      end
    end

    #
    class TemplateEnv

      attr :metadata

      def initialize(metadata)
        @metadata = metadata
      end

      def get_binding
        binding
      end

      #def notelog
      #  File.read('NOTES')
      #end

      #def changelog
      #  File.read('CHANGES')
      #end

      def method_missing(s)
        metadata.send(s)
      end
    end

  end

end






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
            puts "reap #{phase} #{label} #{action}"
          end
        end
      end
=end

