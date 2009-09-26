module Syckles

  # = Till Code Generator Service
  #
  class Till < Service

    cycle :main, :generate

    # Only available if there is a template store.
    #available do |project|
    #  Dir[::Sow::GenericGenerator::TEMPLATE_GLOB].first
    #end

    def preconfigure
      require 'till'
    end

    #
    def safe?; @safe; end

    #
    def generate(options={})
      options ||= {}

      dir = nil # defaults to curent directory

      options[:noop]  = noop?  #safe? #dryrun?
      options[:debug] = debug?
      options[:quiet] = quiet?
      options[:force] = force?

      tiller = Till::Tiller.new(dir, options)
      tiller.till
    end

  end

end

