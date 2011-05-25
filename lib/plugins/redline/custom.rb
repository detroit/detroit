module Redline::Plugins

  # = Custom Plugin
  #
  # Use this plugin to create your own "quicky" service.
  #
  # This is a useful alternative to writing a full-blown plugin
  # class when the need is simple.
  #
  class Custom < Service

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

    # Instantiate new custom plugin.
    #
    # FIXME: Custom#initialize seems to be running twice at startup. Why?
    #
    # This works by interpreting the service configuration as a hash of
    # stop names => ruby code.
    #
    def initialize(context, key, options)
      super
      options.each do |stop, script|
        # skip specific names used for configuration
        next if stop == 'service'
        next if stop == 'track' or stop == 'tracks'
        next if stop == 'active'
        next if stop == 'priority'
        # remaining options are names of track stops
        tracks.each do |t|
          src = %{
            def #{t}_#{stop}
              #{script}
            end
          }
          (class << self; self; end).module_eval(src)
        end
      end
    end

    # Set initial attribute defaults.
    def initialize_defaults
      @track = [DEFAULT_TRACK]
    end

    #
    def method_missing(s, *a, &b)
      super(s, *a, &b) if @context.respond_to?(s)
    end

  end

end
