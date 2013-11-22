module Detroit

  module Assembly

    # TODO: Need to work on how to limit a service's tracks per-assembly.

    # Service class wraps a Tool instance when it is made part of an assembly.
    #
    class Service
      attr :key
      attr :tracks
      attr :priority
      attr :active
      attr :service
      #attr :options

      #
      # Set the priority. Priority determines the order which
      # services on the same stop are run.
      #
      def priority=(integer)
        @priority = integer.to_i
      end

      #
      # Set the tracks a service will be available on.
      #
      def tracks=(list)
        @tracks = list.to_list
      end

      #
      #
      #
      def active=(boolean)
        @active = !!boolean
      end

      #
      # Create new ServiceWrapper.
      #
      def initialize(key, service_class, options)
        @key      = key

        ## set service defaults
        @tracks   = nil #service_class.tracks
        @priority = 0
        @active   = true

        self.active   = options.delete('active')   if !options['active'].nil?
        self.tracks   = options.delete('tracks')   if options.key?('tracks')
        self.priority = options.delete('priority') if options.key?('priority')

        @service = service_class.new(options)
      end

      #
      # Does the service support the given assembly station?
      #
      def stop?(station, stop=nil)
        @service.assemble?(station.to_sym, :destination=>stop.to_sym)
      end

      #
      # Run the service assembly station procedure.
      #
      def invoke(station, stop=nil)
        @service.assemble(station.to_sym, :destination=>stop.to_sym)
      end

      #
      #
      #
      def inspect
        "<#{self.class}:#{object_id} @key='#{key}'>"
      end

    end

  end

end
