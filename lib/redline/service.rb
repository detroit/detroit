require 'redline/service/domain'

module Redline

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
  # The context must be a subclass of Redline::Script.
  #
  #--
  # TODO: Perhaps use a secondary class to delegate the class level.
  #++

  class Service #< Ratch::Plugin

    # Register new instance of the Service class.
    module ClassRegistery

      # Class-level attribute of registered Service subclasses.
      # 
      # Returns a Hash.
      def registry
        @@registry ||= {}
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

    end

    # Service Domain language. This module extends the Service class,
    # to provide a convenience interface for defining stops.
    module DomainLanguage

      # TODO: Err.. Is this being used?
      def init(&block)
        define_method(:init, &block)
      end

      # Designate that service provides a stop on a particular track.
      #
      #   stop '<track>:<stop>'
      #
      # or
      #
      #   stop <track>, <stop>
      #
      # An optional procedure can be given to be run in place of the default
      # action of calling the method named after the stop.
      #
      #   stop '<track>:<stop>' do
      #     ...
      #   end
      #
      # The end result of calling this method is to define an instance method
      # by the name `<track>_<stop>`.
      def stop(track, stop=nil, &block)
        unless stop
          track, stop = *track.split(':')
          track, stop = 'main', track unless stop
        end
        if block
          define_method("#{track}_#{stop}", &block)
        else
          define_method("#{track}_#{stop}") do
            send(stop)
          end
        end
      end

      # Designate the procedure to run just prior to the given stop.
      #
      # The end result of calling this method is to define an instance method
      # by the name `<track>_pre_<stop>`.
      def pre_stop(track, stop=nil, &block)
        unless stop
          track, stop = *track.split(':')
          track, stop = 'main', track unless stop
        end
        stop = "pre_#{stop}".to_sym
        stop(track, stop, &block)
      end

      # Designate the procedure to run just after the given stop.
      #
      # The end result of calling this method is to define an instance method
      # by the name `<track>_aft_<stop>`.
      def aft_stop(track, stop=nil, &block)
        unless stop
          track, stop = *track.split(':')
          track, stop = 'main', track unless stop
        end
        stop = "aft_#{stop}".to_sym
        stop(track, stop, &block)
      end

      #
      def available(&block)
        @available = block if block
        @available ||= nil
      end

      #
      def available?(project)
        return true unless available
        @available.call(project)
      end

      # DEPRECATE: temporarily, this is a no-op to prevent old plugins from breaking.
      def autorun(&block)
      #  @autorun = block if block
      #  @autorun ||= nil
      end

      ##
      #def autorun?(project)
      #  return false unless autorun
      #  @autorun.call(project)
      #end

    end

    #
    module InstanceMethods

      # The batch context.
      attr :context

      #
      attr :key

      #
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

        raise TypeError, "context must be a subclass of Redline::Script" unless context.is_a?(Redline::Script) # Redline::DSL

        initialize_requires
        initialize_defaults

        options ||= {}

        options.each do |k, v|
          send("#{k}=", v) unless v.nil? #if respond_to?("#{k}=") && !v.nil?
        end
      end

      # Require support libraries needed by this service.
      #
      #   def initialize_requires
      #     require 'ostruct'
      #   end
      #
      def initialize_requires
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

    end

    extend ClassRegistery
    extend DomainLanguage

    include InstanceMethods

  end #class Service

end #module Redline

module Redline::Plugins
  Service = Redline::Service
end

# TOPLEVEL DSL?
#def service(name, &block)
#  #Redline.services[name] = Service.factory(&block)
#  Redline::Service.registry[name.to_s] = Redline::Service.factory(&block)
#end

