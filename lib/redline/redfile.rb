require 'facets/to_hash'
#require 'redline/erbio'

module Redline

  def self.project
    @project ||= POM::Project.find
  end

  # Redfile encapsulates a redfile's list of service definitions.
  class Redfile

    # Evaluate a Redfile script.
    def self.eval(script, file=nil)
      new.instance_eval(script, file)
    end

    # Load a Redfile.
    def self.load(io)
      YAML.load(erb(io))
    end

    # Process Redfile document via ERB.
    def self.erb(io)
      text = String === io ? io : io.read
      ERB.new(text).result(__binding__)
    end

    # Provide access to project data.
    def self.project
      Redline.project
    end

    def self.__binding__
      binding
    end

    # Hash table of services.
    attr :services

    # Create new Redfile instance.
    def initialize(services={})
      @services = services.to_h
    end

    # Define a service.
    def service(name, settings={}, &block)
      settings = settings.merge(block.to_h) if block
      @services[name.to_s] = settings
    end

    # Project access to project data.
    def project
      Redline.project
    end

    # Capitalized service names called as methods
    # can also define a service.
    def method_missing(sym, *args, &block)
      service_class = sym.to_s
      case service_class
      when /^[A-Z]/
        if Hash === args.last
          args.last[:service] = service_class
        else
          args << {:services=>service_class}
        end
        service(*args, &block)
      else
        super(sym, *args, &block)
      end
    end

  end

  #
  DOMAIN = "rubyworks.github.com/redline,2011-05-27"

  # TODO: If using Psych rather than Syck, then define a domain type.

  #if defined?(Psych) #RUBY_VERSION >= '1.9'
  #  YAML::add_domain_type(DOMAIN, "redfile") do |type, hash|
  #    Redfile.load(hash)
  #  end
  #else
    YAML::add_builtin_type("redfile") do |type, value|
      case value
      when String
        Redfile.eval(value)
      when Hash
        Redfile.new(value)
      else
        raise
      end
    end
  #end

end
