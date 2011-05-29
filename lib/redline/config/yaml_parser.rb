require 'yaml'

module Redline

  class Config

    # Parse YAML formatted Redfile.
    class YAMLParser

      #
      def self.parse(config, text, file=nil)
        new(config, text, file).__services__
      end

      # Create new YAMLParser.
      def initialize(config, text, file=nil)
        @__config__ = config

        yaml = ERB.new(text).result(__binding__).strip

        @__services__ = YAML.load(yaml) || {}
      end

      # Stores Hash of services and their settings.
      attr :__services__

      # Returns a clean Binding object for use by ERB.
      def __binding__
        binding
      end

      #
      def redfile(file)
        @__config__.redfile(file)
      end

      #
      def project
        @__config__.project
      end

      #
      def method_missing(sym, *args)
        super(sym, *args) unless args.empty?
        @__config__.project.metadata.__send__(sym) #if project.metadata.respond_to?(sym)
      end

    end #class YAMLParser

  end #class Config

end #module Redline
