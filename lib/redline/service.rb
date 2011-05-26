#require 'redtools/tool'
require 'redtools'

module Redline

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

    def priority=(integer)
      @priority = integer.to_i
    end

    def tracks=(list)
      @tracks = list.to_list
    end

    def initialize(key, service_class, options)
      @key      = key

      @tracks   = nil
      @priority = 0
      @active   = true

      @active   = options.delete('active')   if !options['active'].nil?

      self.tracks   = options.delete('tracks')   if options.key?('tracks')
      self.priority = options.delete('priority') if options.key?('priority')

      @service = service_class.new(options)
    end

    #
    def stop?(name)
      @service.respond_to?(name)
    end

    #
    def invoke(name)
      @service.__send__(name)  # public_send
    end
  end

  #
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
        Redline.services
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

      # TODO: Err.. Is this being used?
      def init(&block)
        define_method(:init, &block)
      end

=begin
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
=end

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

    ## The batch context.
    ##attr :context

    #
    #attr :key

    #
    #attr :options

    #
    #attr :tracks

    #
    #attr :priority

    #
    #def priority=(integer)
    #  @priority = integer.to_i
    #end

    #
    #attr_accessor :active


    private

=begin
    # Sets the context and assigns options to setter attributes
    # if they exist and values are not nil. That last point is
    # important. You must use 'false' to purposely negate an option.
    # +nil+ will instead allow any default setting to be used.

    #
    def initialize(key, options={})
      @key = key

      @tracks   = nil
      @priority = 0
      @active   = true

      #@project  = context.project

      @tracks   = options.delete('tracks')   if options.key?('tracks')
      @active   = options.delete('active')   if !options['active'].nil?

      self.priority = options.delete('priority') if options.key?('priority')

      @options = options

      #initialize_requires
      #initialize_defaults

      #@options.each do |k, v|
      #  send("#{k}=", v) if respond_to?("#{k}=") && !v.nil?
      #end
    end
=end

    #attr_reader :service_name
    #attr :project

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

    ## This isn't strictly neccessary since method_missing will
    ## pick it up, but it will make execution a bit faster.
    ##
    #def metadata
    #  project.metadata
    #end

    ##
    ##module Registry
    ##end
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
  # a subclass of RedTools::Tool. Use this class to build Redline services
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

end #module Redline

module Redline::Plugins
  Service = Redline::Service
  Tool    = Redline::Tool
end

# TOPLEVEL DSL?
#def service(name, &block)
#  #Redline.services[name] = Service.factory(&block)
#  Redline::Service.registry[name.to_s] = Redline::Service.factory(&block)
#end

