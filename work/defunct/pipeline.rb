module Reap

  # = Pipeline
  #
  # Reap uses the concepts of development pipelines. These consists of categories of service actions
  # that occur in a specific order, called *phases*. The default pipeline consists of the following
  # consecutive phases. This pipeline is intended to represent the entire development lifecycle.
  #
  #   Configure -> Generate -> Analyize -> Compile -> Test -> Document -> Package -> Release -> Promote -> Archive
  #
  # Thare are two independent phases, Debug, which occurs if the Analysis, Compile or Test phases fail; and
  # Reset which is used to clean products. (NOTE: These phases are still being refined.)
  #
  # Another standard pipeline is the *Site* pipeline, used to update documentation without doing a full release:
  #
  #   Configure -> Generate -> Document -> Release (Publish)
  #
  # And there is a *Attn* pipeline, for making sepcial announcements, besides release announcements.:
  #
  #   Configure -> Generate -> Promote (Announce)
  #
  # Generally these pipelines are enough to satisfy the needs of a project. But if required, alternate
  # pipelines and phases can be defined.
  #
  # All services actions are assigned a phase; they can belong to only one phase per pipeline.
  #
  class PipelineRunner

    #
    attr_reader :project

    #
    attr_reader :pipeline

    #
    attr_reader :services

    #
    attr_reader :actions

    # New Pipeline
    #
    #   services    Array of service objects
    #
    def initialize(project, pipeline, services, actions)
      @project  = project
      @pipeline = pipeline
      @services = services
      @actions  = actions #.reject{ |a| a[1].pipeline != type }
    end


    def run(phase_name)
      system = pipeline.system_with_phase(phase_name)
      system.each do |phase|
        actions.select do |action|
          services[action.service].actions
        end
      end
    end


    #
    def phase_map
      pipeline.phasemap
    end

    #
    def type
      pipeline.name
    end

    #
    def phase_systems
      pipeline.systems
    end

    #
    def io
      project.io
    end

    #
    def root_directory
      project.root_directory
    end

    # Run the pipeline .
    #
    # TODO: use project title not name
    #
    def run(phase_name)
      status_header("#{project.metadata.name.capitalize} v#{project.metadata.version}", "#{root_directory}")
      start_time = Time.now
      invoke(phase_name)
      stop_time = Time.now
      puts "\nFinished in #{stop_time - start_time} seconds." unless project.quiet?
    end

    #
    def phase_actions
      @phase_actions ||= (
        pa = []
        actions.each do |action|
          service_label, action, parameters = action.action, action.method, action.options

          action_label = action.action

          service = services[action.service]

          actions = service.service_class.actions.select{ |a| a.name == action_label && a.pipeline == type }

          actions.each do |action|
            pa << [action.phase, service, action_label, parameters]
          end
        end
        pa
      )
    end

    # Find phase system given a specific phase.
    #
    # Becuase there can be only one phase per system,
    # systems can be uniquely identified with a given phase.
    def find_system(phase_name)
      phase_systems.find do |ps|
        ps.include?(phase_name)
      end
    end



    # Create an action plan.
    def action_plan(phase_name)
#phase_actions.each{ |x| p x }
#puts "---"
      plan = []
      phase_name   = phase_name.to_sym
      phase_system = find_system(phase_name)
      phase_index  = phase_system.index(phase_name)
      phase_plan   = phase_system[0..phase_index]
      phase_plan.each do |phase|
        acts = phase_actions.select{ |pn, *_| pn == phase }
        plan.concat(acts) if acts
      end
      return plan
    end

    
    #
    def select_services
      services.each do |service|
        service.service_class.actions.
      end
    end


    #
    def invoke(phase_name)
      action_plan(phase_name).each do |act|
        execute(act)
      end
    end

    def execute(action_item)
      phase, service, action, parameters = *action_item
      status_line(service.service_title, phase.to_s.capitalize)
      action_method = service.method(action)
      if action_method.arity == 0
        service.send(action) #, parameters)
      else
        service.send(action, parameters)
      end
    end

    # Returns a list of all the phases that terminate a pipleline execution.
    def end_phases
      (phase_map.keys - phase_map.values).compact
    end

    # Give an overview of phases this pipeline supports.
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

      left.color  = 'blue'
      right.color = 'green'

      unless project.quiet?
        puts
        io.printline(left, right, :pad=>2)
        puts "=" * io.screen_width
      end
    end

    #
    #
    def status_line(left, right='')
      left, right = left.to_s, right.to_s

      left.color  = 'blue'
      right.color = 'green'

      unless project.quiet?
        puts
        io.printline(left, right, :pad=>2)
        puts "-" * io.screen_width
      end
    end

    #
    #def screen_width
    #  ConsoleUtils.screen_width
    #end
  end

end
















=begin
  # = Main pipeline
  #
  class MainPipeline < Pipeline
    phase :configure
    phase :generate => :configure
    phase :analyize => :generate
    phase :compile  => :analyize
    phase :validate => :compile
    phase :document => :validate
    phase :package  => :document
    phase :release  => :package
    phase :promote  => :release
    phase :archive  => :promote

    phase :reset
  end

  # = Site Pipeline
  #
  class SitePipeline < Pipeline
    phase :configure
    phase :generate => :configure
    phase :document => :generate
    phase :release  => :document

    phase :reset
  end

  # = Special Announcement Pipeline
  #
  class AttnPipeline < Pipeline
    phase :configure
    phase :generate => :configure
    phase :promote  => :generate

    phase :reset
  end
=end



=begin
    #
    def self.phase(pmap)
      pmap = {pmap => nil} unless Hash===pmap

      pmap.each do |phase_name, pre_phase|
        phase_map[phase_name.to_sym] = pre_phase.to_sym

        class_eval %{
          def #{phase_name}
            invoke(phase_name)
          end
        end

      end
    end
=end

=begin
    # TODO: Don't use name convention, use a register instead.
    #
    def self.factory(type, project, services, actions)
      klass = Reap.const_get("#{type.capitalize}Pipeline")
      klass.new(project, services, actions)
    end

    def self.type
      basename.sub(/Pipeline$/, '').downcase.to_sym
    end

    def self.phase_map
      @phase_map ||= {}
    end

    def self.phase(map)
      case map
      when String, Symbol
        phase_map[map.to_sym] = nil
      else
        map.each do |phase, pre_phase|
          phase_map[phase.to_sym] = pre_phase.to_sym
        end
      end
    end

    #
    def self.phase_systems
      systems = []
      end_phases = (phase_map.keys - phase_map.values).compact
      end_phases.each do |end_phase|
        system = []
        x = end_phase
        until x == nil
          system.unshift(x)
          x = phase_map[x]
          raise "recursive pipleine -- #{type}/#{x}" if system.include?(x)
        end
        systems << system
      end
      return systems
    end
=end
