module Detroit

  # All assemblies and tracks have a maintenance sub-track.
  # For this reason stop names `reset`, `clean` and `purge`
  # are reserved names and MUST not be used as stop names
  # in defining custom lines.
  MAINTENANCE_TRACK = [:reset, :clean, :purge]

  # Returns Hash of name and Circuit instance pairs.
  def self.assembly_systems
    @assembly_system ||= {}
  end

  # Define a new assembly system.
  def self.assembly_system(name, &block)
    assembly_systems[name.to_sym] = AssemblySystem.new(name, &block)
  end

  # The AssemblySystem class encapsulates  a set of interrelated
  # assembly lines, or _tracks_.
  class AssemblySystem

    # Name of the assembly system.
    attr :name

    # Returns a Hash of track names mapped to list of stops.
    attr :lines

    # Lines are also called `tracks`.
    alias_method :tracks, :lines

    # Create a new instance.
    def initialize(name, &block)
      @name   = name.to_sym
      @lines  = {:maintenance => MAINTENANCE_TRACK}
      instance_eval(&block) if block
    end

    # Define an assembly line.
    def line(name, *stops)
      if stops.empty?
        @lines[name.to_sym]
      else
        @lines[name.to_sym] = stops.map{ |s| s.to_sym }
      end
    end

    # Lines are also called tracks.
    alias_method :track, :line

    # Lookup track by name and (optional) stop. If the stop belongs
    # to the maintenance sub-track then the maintenance sub-track will
    # be returned instead of the track itself.
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

    # Did I mention that `line` and `track` are synonyms?
    alias_method :get_line, :get_track

  end

end
