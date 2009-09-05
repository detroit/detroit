module Reap
  require 'reap/plugins'

  #
  class System < Module

    #
    def services
      @services ||= {}
    end

    #
    def availablity
      @availablity ||= {}
    end

    #
    def cycles
      @cycles ||= []
    end

    #
    def service(name, &block)
      #services[name] = block
      define_method(name)
        block.call(options)
      end
    end

    #
    def available(name, &block)
      availablity[name] = block
    end

    # Use this to designate cycle.
    #
    #   cycle '<name>:<phase>' do
    #     ...
    #   end
    #
    def cycle(phase, options={}, &block)
      cycles << Cycle.new(phase, options, &block)
    end

  end


  class Cycle
    attr_accessor :priority
    def initialize(phase, options={}, &block)
      name,phase = *phase.split(':')
      name,phase = 'main',name if !phase
      @name  = name
      @phase = phase
      @block = block
      options.each{ |k,v| __send__("#{k}=", v) }
    end
    def match?(name,phase)
      name == @name && phase == @phase
    end
    def <=>(other)
      priority <=> other.priority
    end
    def call
      @block.call
    end
  end

  #  def available?(project)
  #    return true unless @available
  #    @available.call(project) # how to get project in here?
  #  end

    # TODO: support auto available (?)
    #def auto_available(&block)
    #  @auto_available = block if block
    #  @auto_available
    #end

    #
    #def auto_available?(project)
    #  return true unless @auto_available
    #  @auto_available.call(project)
    #end

  #
  class Runner

    attr :system
    attr :config

    def initialize
      load_plugins
      load_configs
    end

    #
    def run(phase)
      name,phase = *phase.split(':')
      name,phase = 'main',cycle if !phase
      cycles[name].each do |phase|
        set = system.cycles.select do |cycle|
          cycle.match?(name,phase)
        end
        set.sort.each do |cycle|
          cycle.call
        end
      end
    end

    #
    def load_configs
      config = {}
      files = []
      files += project.task.glob('*.reap')
      files += project.script.glob('*.reap')
      files.each do |file|
        tmp = Tmp.new(project.metadata)
        erb = ERB.new(File.read(file))
        txt = erb.result(tmp._binding)
        cfg = YAML.load(txt)
        config.update(conf || {})
      end
      @config = config
    end

    #
    def load_plugins
      system = System.new
      Reap.plugins.each do |file|
        system.instance_eval(File.read(file))
      end
      @system = system
    end

    #def plugin_files
    #  $LOAD_PATH.map do |path|
    #    Dir[File.join(path, 'scythes/*.rb')]
    #  end.flatten.uniq
    #  # TODO: Handle Roll
    #  # TODO: Handle Gems
    #end

  end

end

