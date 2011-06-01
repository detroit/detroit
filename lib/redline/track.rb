module Redline

  # Stores the defined lines.
  #
  # Retruns Hash of name and track instance pairs.
  def self.tracks
    @tracks ||= {}
  end

  # Define a new track.
  def self.track(name, &block)
    tracks[name.to_sym] = Track.new(name, &block)
  end

  # The Track class encapsulates the definition of
  # a track/line. 
  class Track

    # Name of the track.
    attr :name

    # Routes on the track.
    attr :routes

    #alias_method :tracks, :routes

    # Create a new instance of Track.
    def initialize(name, &block)
      @name     = name.to_sym
      @routes   = []
      instance_eval(&block) if block
    end

    # Define a route within the track.
    def route(*stops)
      @routes << stops.map{ |s| s.to_sym }
    end

    # Lookup routes that have a given stop.
    def route_with_stop(stop)
      routes.find{ |c| c.include?(stop.to_sym) }
    end

  end

end
