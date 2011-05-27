module Redline
  class Config
    #
    class RubyParser
      # undefine most methods
      KEEP_METHODS = /^(__|instance_|require$|load$)/
      public_instance_methods.each do |m|
        undef_method m unless KEEP_METHODS =~ m.to_s
      end

      def self.parse(&block)
        new(&block).__services__
      end

      # Stores Hash of services and their settings.
      attr :__services__

      #
      def initialize(config, text, file=nil)
        @__config__   = config
        @__services__ = {}
        instance_eval(text, file)
      end

      #
      def method_missing(service, name=nil, *args, &block)
        name = (name || service).to_s
        @__services__[name] = SettingsParser.parse(&block)
        @__services__[name]['service'] = service.to_s
        @__services__[name]
      end

      # TODO: This should probably be a subclass of BasicObject or it needs to use 
      # setter notation instead of instance_eval. The former is the most robust,
      # but the later can work if we are very explict about methods in the context.
      class SettingsParser
        # undefine most methods
        KEEP_METHODS = /^(__|instance_|p$)/
        public_instance_methods.each do |m|
          undef_method m unless KEEP_METHODS =~ m.to_s
        end

        # Initialize new SettingsParser and return parsed settings.
        def self.parse(&block)
          new(&block).__settings__
        end

        # Stores a Hash of settings.
        attr :__settings__

        #
        def initialize(&block)
          @__settings__ = {}
          instance_eval(&block) if block
        end

        #
        def method_missing(name, *args, &block)
          value = args.first
          if block_given?
            @__settings__[name.to_s] = SettingsParser.parse(&block)
          else
            @__settings__[name.to_s] = value
          end
        end

      end #class SettingsParser

    end #class RubyParser

  end #class Config

end #module Redline
