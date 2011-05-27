module Redline

  class Config

    # The RubyParser parses Ruby-based redfiles.
    #
    class RubyParser
      # undefine most methods
      KEEP_METHODS = /^(__|instance_|require$|load$|gem$)/
      public_instance_methods.each do |m|
        undef_method m unless KEEP_METHODS =~ m.to_s
      end

      def self.parse(config, text, file=nil, &block)
        new(config, text, file, &block).__services__
      end

      # Stores Hash of services and their settings.
      attr :__services__

      # Create new instance of RubyParser.
      def initialize(config, text, file=nil)
        @__config__   = config
        @__services__ = {}
        instance_eval(text, file)
      end

      # TODO: Should we enforce capitalization of service names?
      def method_missing(service, name=nil, *args, &block)
        name = (name || service).to_s.downcase
        if block
          @__services__[name] = SettingsParser.parse(&block)
        else
          @__services__[name] = {}
        end
        @__services__[name]['service'] = service.to_s
        @__services__[name]
      end

      # TODO: This should probably be a subclass of BasicObject.
      class SettingsParser
        # undefine most methods
        KEEP_METHODS = /^(__|instance_|initialize$|p$)/
        (public_instance_methods + protected_instance_methods + private_instance_methods).each do |m|
          undef_method m unless KEEP_METHODS =~ m.to_s
        end

        # Initialize new SettingsParser and return parsed settings.
        def self.parse(&block)
          new(&block).__settings__
        end

        # Stores a Hash of settings.
        attr :__settings__

        # Create a new instance of SettingsParser.
        def initialize(&block)
          @__settings__ = {}
          if block.arity == 1
            block.call(self)
          else
            instance_eval(&block)
          end
        end

        # 
        def method_missing(name, *args, &block)
          name  = name.to_s.chomp('=')
          value = args.first
          if block
            @__settings__[name] = SettingsParser.parse(&block)
          else
            @__settings__[name] = value
          end
        end

      end #class SettingsParser

    end #class RubyParser

  end #class Config

end #module Redline