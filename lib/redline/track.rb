module Redline

  #
  def self.tracks
    @tracks ||= {}
  end

  # Define a new track.
  def self.track(name, &block)
    tracks[name.to_sym] = Track.new(name, &block)
  end

  #
  class Track
    #
    attr :name

    #
    attr :routes
    #alias_method :tracks, :routes

    #
    def initialize(name, &block)
      @name     = name.to_sym
      @routes   = []
      instance_eval(&block) if block
    end

    #
    def route(*stops)
      @routes << stops.map{ |s| s.to_sym }
    end
    

    #
    def route_with_stop(stop)
      routes.find{ |c| c.include?(stop.to_sym) }
    end

  end

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

