module Reap

  class Project

    # = Project Settings Defaults
    #
    # Provides an inteface to default values for Settings.
    # The default values are loaded from a .yaml file.

    class Defaults < Hash

      DEFAULT_FILE = File.join(File.dirname(__FILE__), 'default.yaml')

      attr :metadata

      # FIXME: when using the settings, I think nil should be considered a none entry and
      # so false would be required to actually mean "off". This means assigning each key value par one a time?

      def initialize(metadata)
        super()
        @metadata = metadata
        defaults = File.read(DEFAULT_FILE)
        defaults = instance_eval("<<-XXXXXXXXXXXXX\n#{defaults}\nXXXXXXXXXXXXX")
        defaults = YAML::load(defaults)
        #settings = defaults.dup
        #data.each do |key, value|
        #  settings[key] ||= {}
        #  settings[key].update(value) if value
        #end
        update(defaults)
      end

      # open hash

      def method_missing(s, *a)
        if s =~ /=$/
          self[s] = a[0]
        elsif a.empty?
          self[s]
        else
          super
        end
      end

    end

  end

end
