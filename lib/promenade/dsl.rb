module Promenade

  # NOT YET IN USE.
  module DSL

    # Define a track.
    #
    # Examples
    #
    #   track :site do
    #     route :maintainence do
    #       stops :reset, :clean, :purge
    #     end
    #   end
    #
    def track(&block)
      Track.new(&block)
    end

    # Define a service.
    #
    # Examples
    #
    #   service :foo do
    #     reset do
    #       utime(0,0, project.path(:log) + 'foo.log')
    #     end
    #   end
    #
    def service(name, &block)
      Service.registry[name.to_s] ||= ServiceDSL.new(&block).service_class
    end

    # ServiceDSL is used to define services via the Promenade DSL.
    class ServiceDSL < BasicObject
      attr :service_class

      def initialize(name, &block)
        @service_class = Class.new(Promenade::Service)
      end

      def available(&block)
        (class << @service_class; self; end).class_eval do
          define_method(:available?, &block)
        end
      end

      def method_missing(name, *args, &block)
        @service_class.define_method(name, &block)
      end
    end

  end

end
