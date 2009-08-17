module Reap

  # Pipelines mapping.
  #
  def self.pipelines
    @pipelines ||= {}
  end

  # Define a new pipeline.
  #
  def self.pipeline(name, &block)
    pipelines[name.to_sym] = Pipeline.new(name, &block)
  end

  # = Pipeline
  #
  class Pipeline
    attr :phasemap

    def initialize(name, &block)
      @name     = name.to_sym
      @phasemap = {}
      instance_eval(&block)
    end

    #
    def phase(map)
      case map
      when String, Symbol
        phasemap[map.to_sym] = nil
      else
        map.each do |post_phase, pre_phase|
          phasemap[post_phase.to_sym] = pre_phase.to_sym
        end
      end
    end

    #
    def systems
      @systems ||= calc_systems
    end

    #
    def system_with_phase(phase)
      systems.find{ |s| s.include?(phase) }
    end

    private

    #
    def calc_systems
      systems = []
      end_phases = (phasemap.keys - phasemap.values).compact
      end_phases.each do |end_phase|
        system = []
        x = end_phase
        until x == nil
          system.unshift(x)
          x = phasemap[x]
          raise "recursive pipleine -- #{type}/#{x}" if system.include?(x)
        end
        systems << system
      end
      return systems
    end

  end

end

