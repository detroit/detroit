#require 'reap/domain'

# DSL method for creating a service.
def service(name, &block)
  Reap::Plugin.registry[name.to_s.downcase] = Class.new(Reap::Plugin, &block)
end

module Reap

  def self.services
    Plugin.registry
  end

  # = Plugin
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
  # The context must be a subclass of Reap::Domain.
  #
  class Plugin

    # The batch context.
    attr :context

    attr :key

    attr_accessor :priority

    private

    # Sets the context and assigns options to setter attributes
    # if they exist and values are not nil. That last point is
    # important. You must use 'false' to purposely negate an option.
    # +nil+ will instead allow any default setting to be used.

    #
    def initialize(context, key, options=nil)
      @context  = context
      @project  = context.project
      @key      = key

      @priority = 0

      raise TypeError, "context must be a subclass of Reap::DSL" unless context.is_a?(Reap::Domain) # Reap::DSL

      initialize_defaults

      options ||= {}
      options.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=") && !v.nil?
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
    module Registry

      #
      def registry
        @@registry ||= {}
      end

      # TODO: Probably should make a named registry instead.
      def inherited(base)
        return if base.name.to_s.empty?
        if base.name !~ /Plugin$/
          registry[base.basename.downcase] = base
        end
      end

      #
      def available(&block)
        @available = block if block
        @available
      end

      def available?(project)
        return true unless @available
        @available.call(project)
      end

      # TODO: support auto available.
      def auto_available(&block)
        @auto_available = block if block
        @auto_available
      end

      #
      def auto_available?(project)
        return true unless @auto_available
        @auto_available.call(project)
      end

      #
      #def actions
      #  @actions ||= []
      #end

      #
      #def service_actions
      #  @service_actions ||= Hash.new{|h,k| h[k]={}}
      #end

      # Use this to designate service action(s).
      #
      #   pipeline <pipe>, <phase> do
      #     ...
      #   end
      #
      def pipeline(pipeline, phase, &block)
        if block
          define_method("#{pipeline}_#{phase}", &block)
        else
          define_method("#{pipeline}_#{phase}") do
            send(phase)
          end
        end
      end

      #def pipeline(pipeline, method_to_phase=nil)
      #  if method_to_phase
      #    method_to_phase.each do |meth, phase|
      #      #actions << Action.new(pipeline, phase, meth)
      #
      #      service_actions[pipeline]
      #      service_actions[pipeline][phase] ||= []
      #      service_actions[pipeline][phase] << meth.to_sym
      #    end
      #  else
      #    #actions << Action.new(pipeline)
      #    service_actions[pipeline] = nil  # match_by_method
      #  end
      #end

      alias_method :pipe, :pipeline
      #alias_method :cycle, :pipeline

      #
      #def supports(pipe, phase)
      #  pipe, phase = pipe.to_sym, phase.to_sym
      #  return [] unless service_actions.key?(pipe)
      #  if service_actions[pipe]
      #    return [] unless service_actions[pipe].key?(phase)
      #    return service_actions[pipe][phase]
      #  else
      #    return [phase] if instance_methods.find{ |im| im.to_sym == phase }
      #  end
      #  return []
      #end

      #
      #def acts(pipe, phase)
      #  #@actions.select{ |a| a.pipe == pipe & a.phase == phae }
      #  return nil unless service_actions[pipe]
      #  service_actions[pipe][phase]
      #end

    end

    extend Registry

  end #class Plugin

end #module Reap

