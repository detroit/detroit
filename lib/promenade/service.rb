module Promenade

  #
  def self.services
    @registry ||= {}
  end

  # TODO: change name
  class ServiceWrapper
    attr :key
    attr :tracks
    attr :priority
    attr :active
    attr :service
    #attr :options

    # Set the priority. Priority determines the order which
    # services on the same stop are run.
    def priority=(integer)
      @priority = integer.to_i
    end

    # Set the tracks a service will be available on.
    def tracks=(list)
      @tracks = list.to_list
    end

    #
    def active=(boolean)
      @active = !!boolean
    end

    # Create new ServiceWrapper.
    def initialize(key, service_class, options)
      @key      = key

      ## set service defaults
      @tracks   = service_class.tracks
      @priority = 0
      @active   = true

      self.active   = options.delete('active')   if !options['active'].nil?
      self.tracks   = options.delete('tracks')   if options.key?('tracks')
      self.priority = options.delete('priority') if options.key?('priority')

      @service = service_class.new(options)
    end

    # Does the service support the given stop.
    def stop?(name)
      @service.respond_to?(name)
    end

    # Run the service stop procedure.
    def invoke(name)
      @service.__send__(name)  # public_send
    end

    #
    def inspect
      "<#{self.class}:#{object_id} @key='#{key}'>"
    end
  end

  # Mixin module is added to Service and Tool.
  module Serviceable

    #
    def self.included(base)
      base.extend ClassRegistry
      base.extend DomainLanguage
    end

    # Register new instance of the Service class.
    module ClassRegistry

      # Class-level attribute of registered Service subclasses.
      # 
      # Returns a Hash.
      def registry
        Promenade.services
      end

      # TODO: Probably should make a named registry instead.
      def inherited(base)
        return if base.name.to_s.empty?
        if base.name !~ /Service$/
          registry[base.basename.downcase] = base
        end
      end

      # Returns a Class which is a new subclass of the current class.
      def factory(&block)
        Class.new(self, &block)
      end

      #
      def options(service_class=self)
        service_class.instance_methods.
          select{ |m| m.to_s =~ /\w+=$/ && !%w{taguri=}.include?(m.to_s) }.
          map{ |m| m.to_s.chomp('=') }
      end

    end

    # Service Domain language. This module extends the Service class,
    # to provide a convenience interface for defining stops.
    module DomainLanguage
      ## TODO: Err.. Is this being used?
      #def init(&block)
      #  define_method(:init, &block)
      #end

      # Override the `tracks` method to limit the lines a service
      # will work with by default. Generally this is not used,
      # and a return value of +nil+ means all lines apply.
      def tracks
      end

      # TODO: Perhaps deprecate this in favor of just defining an `availabe?`
      # class method.
      def available(&block)
        @available = block if block
        @available ||= nil
      end

      #
      def available?(project)
        return true unless available
        @available.call(project)
      end
    end

    #attr_reader :service_name

    #
    def service_title
      self.class.name
    end

    # TODO: Is this being used?
    #def service_actions
    #  self.class.service_actions
    #end

    #
    #def inspect
    #  "<#{self.class}:#{object_id}>"
    #end
  end

  # The Service class is the base class for defining basic or delgated services.
  class Service
    include Serviceable

    #
    attr :options

    def initialize(options={})
      @options = options
    end
  end

  # Tool class is essentially the same as a Service class except that it is
  # a subclass of RedTools::Tool. Use this class to build Promenade services
  # with all the conveniences of a RedTools::Tool.
  class Tool < RedTools::Tool
    include Serviceable

    #
    attr :options

    def initialize(options={})
      @options = options
      super(options)
    end
  end

end #module Promenade

# Provides a clean namespace for creating services.
module Promenade::Plugins
  Service = Promenade::Service
  Tool    = Promenade::Tool
end

# TOPLEVEL DSL?
#def service(name, &block)
#  #Promenade.services[name] = Service.factory(&block)
#  Promenade::Service.registry[name.to_s] = Promenade::Service.factory(&block)
#end

