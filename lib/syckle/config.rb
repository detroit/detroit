module Syckle

  # Syckle master configuration. Configuration settings load
  # load from a YAML project file saved as '.config/syckle.yml'.
  class Config

    # Use automatic services feature?
    attr_accessor :automatic

    # Services to omit from automatic execution.
    # Should be an array of class basenames.
    attr_accessor :auto_omit

    def initialize
      @automatic = false
      @auto_omit = []

      file = Dir['.config/syckle.{yml,yaml}'].first
      if file
        conf = YAML.load(File.new(file))
        conf.each do |k,v|
          __send__("#{k}=", v) if respond_to?("#{k}=")
        end
      end
    end

    # Use automatic services?
    def automatic?
      @automatic
    end

    # Set list of services to omit from automatic execution.
    def auto_omit=(entry)
      @auto_omit = [entry].flatten.map{ |n| n.to_s.downcase }
    end

  end

end
