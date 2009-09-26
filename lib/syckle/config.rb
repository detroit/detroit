module Syckle

  class Config

    attr_accessor :automatic

    attr_accessor :auto_omit

    def initialize
      @automatic = false
      @auto_omit = []

      file = Dir['.config/syckle.yml'].first
      if file
        conf = YAML.load(File.new(file))
        conf.each do |k,v|
          __send__("#{k}=", v) if respond_to?("#{k}=")
        end
      end
    end

    def automatic?
      @automatic
    end

    def auto_omit=(entry)
      @auto_omit = [entry].flatten
    end

  end

end
