module Detroit

  # All circuits and tracks have a maintenance track/sub-track.
  # For this reason stop names `reset`, `clean` and `purge`
  # are reserved names and MUST not be used in defining
  # custom circuts or tracks.
  MAINTENANCE_TRACK = [:reset, :clean, :purge]

  # Retruns Hash of name and Circuit instance pairs.
  def self.circuits
    @circuits ||= {}
  end

  # Define a new cuircuit.
  def self.circuit(name, &block)
    circuits[name.to_sym] = Circuit.new(name, &block)
  end

  # The Circuit class encapsulates the definition of
  # a set of interrelated tracks. 
  class Circuit

    # Name of the circuit.
    attr :name

    # Returns a Hash of track names mapped to list of stops.
    attr :tracks

    # Create a new instance of Track.
    def initialize(name, &block)
      @name   = name.to_sym
      @tracks = {:maintenance => MAINTENANCE_TRACK}
      instance_eval(&block) if block
    end

    # Define a route within the circuit.
    def track(name, *stops)
      if stops.empty?
        @tracks[name.to_sym]
      else
        @tracks[name.to_sym] = stops.map{ |s| s.to_sym }
      end
    end

    # Lookup track by name and (optional) stop. If the stop belongs
    # to the maintenance sub-track then the maintenance sub-track will be
    # returned instead of the track itself.
    #
    # The Application class uses this to simplify track lookup.
    def get_track(name, stop=nil)
      name = name.to_sym
      if stop
        stop = stop.to_sym
        if MAINTENANCE_TRACK.include?(stop.to_sym)
          track = MAINTENANCE_TRACK
        else
          track = tracks[name]
            raise "Unknown track `#{name}'." unless track
          unless track.include?(stop)
            raise "Unknown stop `#{stop}` for track `#{name}'."
          end
        end
      else
        track = tracks[name]
      end
      track
    end

  end

end
