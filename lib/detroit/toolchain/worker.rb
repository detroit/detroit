module Detroit

  module Toolchain

    # TODO: Need to work on how to limit a service's groups per-assembly.

    ##
    # Service class wraps a Tool instance when it is made part of an assembly.
    #
    # TODO: Perhpas a better name would be `Link`, as in "chain link"?
    #
    class Worker

      attr :key
      attr :groups
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
      def groups=(list)
        @groups = list.to_list
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
        @groups   = nil
        @priority = 0
        @active   = true

        self.active   = options.delete('active')   if !options['active'].nil?
        self.groups   = options.delete('groups')   if options.key?('groups')
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

end
