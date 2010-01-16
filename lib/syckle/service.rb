# = Service Loader
#
module Syckle

  #
  def self.services
    Service.registry
  end

  # = Service
  #
  # The plugin acts a base class for ecapsulating batch routines.
  # This helps to keep the main batch context free of the clutter
  # of private supporting methods.
  #
  # Plugins are tightly coupled to the batch context,
  # which allows them to call on the context easily.
  # However this means plugins cannot be used independent
  # of a batch context, and changes in the batch context
  # can cause effects in plugin behvior that can be harder
  # to track down and fix if a bug arises.
  #
  # The context must be a subclass of Syckle::Script.
  #
  #--
  # TODO: Perhaps use a secondary class to delegate the class level.
  #++

  class Service #< Ratch::Plugin

    def self.registry
      @@registry ||= {}
    end

    # TODO: Probably should make a named registry instead.
    def self.inherited(base)
      return if base.name.to_s.empty?
      if base.name !~ /Service$/
        registry[base.basename.downcase] = base
      end
    end

    #
    def self.factory(&block)
      Class.new(self, &block)
    end

    # NOTE: How is this being used?
    def self.init(&block)
      define_method(:init, &block)
    end

    # Define the procedure for a given cycle-phase.
    #
    #   cycle '<cycle>:<phase>' do
    #     ...
    #   end
    #
    def self.cycle(name, phase=nil, &block)
      unless phase
        name, phase = *name.split(':')
        name, phase = 'main', name unless phase
      end
      if block
        define_method("#{name}_#{phase}", &block)
      else
        define_method("#{name}_#{phase}") do
          send(phase)
        end
      end
    end

    # Designate the procedure to run prior to the main
    # cycle procedure.
    def self.precycle(name, phase=nil, &block)
      unless phase
        name, phase = *name.split(':')
        name, phase = 'main', name unless phase
      end
      phase = ('pre_' + phase.to_s).to_sym
      cycle(name, phase, &block)
    end

    # Designate the procedure to run after the main
    # cycle procedure.
    def self.aftcycle(name, phase=nil, &block)
      unless phase
        name, phase = *name.split(':')
        name, phase = 'main', name unless phase
      end
      phase = ('aft_' + phase.to_s).to_sym
      cycle(name, phase, &block)
    end

    #
    def self.available(&block)
      @available = block if block
      @available ||= nil
    end

    #
    def self.available?(project)
      return true unless available
      @available.call(project)
    end

    #
    def self.autorun(&block)
      @autorun = block if block
      @autorun ||= nil
    end

    #
    def self.autorun?(project)
      return false unless autorun
      @autorun.call(project)
    end


    # The batch context.
    attr :context

    attr :key

    attr :options

    #
    attr_accessor :priority

    #
    attr_accessor :active

    #

    private

    # Sets the context and assigns options to setter attributes
    # if they exist and values are not nil. That last point is
    # important. You must use 'false' to purposely negate an option.
    # +nil+ will instead allow any default setting to be used.

    #
    def initialize(context, key, options={})
      @context  = context
      @project  = context.project
      @key      = key
      @options  = options || {}

      @priority = 0
      @active   = true

      raise TypeError, "context must be a subclass of Syckle::Script" unless context.is_a?(Syckle::Script) # Syckle::DSL

      initialize_defaults

      options ||= {}

      options.each do |k, v|
        send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
      end
    end

    # When subclassing, put default instance variable settngs here.
    # Eg.
    #
    #   def initialize_defaults
    #     @gravy = true
    #   end
    #
    def initialize_defaults
    end

    # TODO: Allow this to be optional? How?
    #
    def method_missing(s, *a, &b)
      @context.send(s, *a, &b)
    end

    #
    #attr_reader :service_name

    #
    attr :project


    #
    def service_title
      self.class.name
    end

    #
    def service_actions
      self.class.service_actions
    end

    #
    def inspect
      "<#{self.class}:#{object_id}>"
    end

    # Override this method to return the files
    # # TODO: An automatic way to check for "need".
    #def resource_files
    #end

    # This isn't strictly neccessary since method_missing will
    # pick it up, but it will make execution a bit faster.
    #
    def metadata
      project.metadata
    end

    # = Plugin Registry MetaMixin
    #
    #module Registry
    #end

    #extend Registry

  end #class Service

end #module Syckle

module Syckle::Plugins
  Service = Syckle::Service
end

# TOPLEVEL DSL?
#def service(name, &block)
#  #Syckle.services[name] = Service.factory(&block)
#  Syckle::Service.registry[name.to_s] = Syckle::Service.factory(&block)
#end

