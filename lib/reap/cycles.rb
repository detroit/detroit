module Reap #Sykle

  #
  def self.lifecycles
    @lifecycles ||= {}
  end

  # Define a new lifecycle.
  #
  def self.lifecycle(name, &block)
    lifecycles[name.to_sym] = LifeCycle.new(name, &block)
  end

  # = LifeCycle
  #
  class LifeCycle

    #
    attr :cycles

    #
    def initialize(name, &block)
      @name     = name.to_sym
      @cycles   = []
      instance_eval(&block) if block
    end

    #
    def cycle(*phases)
      @cycles << phases.map{ |s| s.to_sym }
    end

    #
    def cycle_with_phase(phase)
      cycles.find{ |c| c.include?(phase.to_sym) }
    end

  end#class LifeCycle

end



=begin

    #
    #def phase(map)
    #  case map
    #  when String, Symbol
    #    phasemap[map.to_sym] = nil
    #  else
    #    map.each do |post_phase, pre_phase|
    #      phasemap[post_phase.to_sym] = pre_phase.to_sym
    #    end
    #  end
    #end

    #
    #def systems
    #  @systems ||= calc_systems
    #end

    #private

    #
    #def calc_systems
    #  systems = []
    #  end_phases = (phasemap.keys - phasemap.values).compact
    #  end_phases.each do |end_phase|
    #    system = []
    #    x = end_phase
    #    until x == nil
    #      system.unshift(x)
    #      x = phasemap[x]
    #      raise "recursive pipleine -- #{type}/#{x}" if system.include?(x)
    #    end
    #    systems << system
    #  end
    #  return systems
    #end

=end

