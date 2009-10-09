module Syckle::Plugins

  # = Till Generation Service
  #
  class Till < Service

    cycle :main, :generate
    cycle :site, :generate

    # Make automatic?
    #autorun do
    #  ...
    #end

    available do |project|
      begin
        require 'till'
        true
      rescue LoadError
        false
      end
    end

    #
    #def safe?; @safe; end

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

