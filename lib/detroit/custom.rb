module Detroit

  # Custom tool is used to create "quicky" services.
  #
  # This is a useful alternative to writing a full-blown plugin
  # when the need is simple.
  #
  class Custom < Tool

    # Default track(s) in which this plugin operates.
    DEFAULT_TRACK = "main"

    # Which track(s) to run this custom plugin.
    attr_accessor :track

    # Special writer to allow single track or a list of tracks.
    def track=(val)
      @track = val.to_list #[val].flatten
    end

    # Plural alias for #track.
    alias_accessor :tracks, :track

    private

    SPECIAL_OPTIONS = %w{
      service track tracks active priority project 
      trial trace verbose force quiet
    }

    # Instantiate new custom plugin.
    #
    # FIXME: Custom#initialize seems to be running twice at startup. Why?
    #
    # This works by interpreting the service configuration as a hash of
    # stop names to ruby code.
    #
    def initialize(options)
      super(options)
      options.each do |stop, script|
        # skip specific names used for configuration
        next if SPECIAL_OPTIONS.include? stop
        # remaining options are names of track stops
        #tracks.each do |t|
          src = %{
            def station_#{stop}
              #{script}
            end
          }
          (class << self; self; end).module_eval(src)
        #end
      end
    end

    # Set initial attribute defaults.
    def initialize_defaults
      @track = [DEFAULT_TRACK]
    end

    #
    def method_missing(s, *a, &b)
      if @context.respond_to?(s)
        @context.__send__(s,*a,&b)
      else
        super(s, *a, &b)
      end
    end

    public

    #
    #def respond_to?(name)
    #  r = super(name)
    #  return r if r
    #  @context.respond_to?(s)
    #end

  end

end
