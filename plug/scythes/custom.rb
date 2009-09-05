module Syckles

  # = Custom Plugin
  #
  # Use this plugin to create your own "quicky" Reap service.
  #
  # This is a useful alternative to writing a full-blown plugin
  # class when the need is simple.
  #
  class Custom < Service

    # Default pipeline(s) in which this plugin operates.
    DEFAULT_PIPELINE = "main"

    # Which pipeline(s) to run this custom plugin.
    attr_accessor :pipeline

    # Plural alias for #pipeline.
    alias_accessor :pipelines, :pipeline

    # Special writer to allow single pipeline or a list of pipelines.
    def pipeline=(val)
      @pipeline = [val].flatten
    end

  private

    # Instantiate new custom plugin.
    #
    # FIXME: Custom#initialize seems to be running twice at startup. Why?
    #
    def initialize(context, key, options)
      super
      options.each do |phase, script|
        # skip reap specific config options
        next if phase == 'service'
        next if phase == 'pipeline' or key == 'pipelines'
        next if phase == 'active'
        next if phase == 'priority'
        # remaining options are names of pipeline phases
        pipelines.each do |pipe|
          src = %{
            def #{pipe}_#{phase}
              #{script}
            end
          }
          (class << self; self; end).module_eval(src)
        end
      end
    end

    # Set initial attribute defaults.
    def initialize_defaults
      @pipeline  = DEFAULT_PIPELINE
    end

  end

end
