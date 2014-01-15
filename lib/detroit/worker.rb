module Detroit

  ##
  # Service class wraps a Tool instance when it is made part of an assembly.
  #
  # TODO: Perhpas a better name would be `Link`, as in "chain link"?
  #
  # TODO: We may be able to get rid of this class if we move this code into
  #        the BasicTool class instead.
  #
  class Worker

    attr :key
    attr :track
    attr :priority
    attr :active
    attr :tool
    #attr :options

    # Set the priority. Priority determines the order which
    # services on the same stop are run.
    #
    def priority=(integer)
      @priority = integer.to_i
    end

    # Set the tracks a service will be available on.
    #
    def track=(list)
      @track = list.to_list
    end

    #
    def active=(boolean)
      @active = !!boolean
    end

    # Create new wrapper.
    #
    def initialize(key, tool_class, options)
      @key = key

      ## set defaults
      @track    = nil
      @priority = 0
      @active   = true

      self.active   = options.delete('active')   if !options['active'].nil?
      self.track    = options.delete('track')    if options.key?('track')
      self.priority = options.delete('priority') if options.key?('priority')

      @tool = tool_class.new(options)
    end

    # Does the tool handle the given assembly station?
    #
    # If `true` is returned than the station is handled by a method
    # in the tool with the same name.
    #
    # If a symbol is returned then the station is handled, but via
    # the method named by the returned symbol.
    #
    # @return [Boolean,Symbol]
    def stop?(station, stop=nil)
      @tool.assemble?(station.to_sym, :destination=>stop.to_sym)
    end

    # Run the service assembly station procedure.
    #
    def invoke(station, stop=nil)
      @tool.assemble(station.to_sym, :destination=>stop.to_sym)
    end

    #
    def inspect
      "<#{self.class}:#{object_id} @key='#{key}'>"
    end

  end

end
