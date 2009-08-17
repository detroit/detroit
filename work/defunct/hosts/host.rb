require 'reap/tool'

module Reap
module Hosts

  def self.registry
    @registry ||= {}
  end

  # = Host
  #
  # Base class for Hosts.

  class Host < Tool

    def self.registry
      Hosts.registry
    end

    def self.register(*uris)
      uris.each do |uri|
        registry[uri] = self
      end
    end

    def self.inherited(base)
      scm = base.basename.downcase
      registry[scm] = base
    end

    def self.factory(name)
      registry[name]
    end

    # Generic announce confirmation.

    def announce_confirm?(options={})
      return true if force?
      ans = ask("Announce to #{self.class.basename.downcase}?", "yN")
      case ans.downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    # Generic announce confirmation.

    def release_confirm?(options={})
      return true if force?
      ans = ask("Release to #{self.class.basename.downcase}?", "yN")
      case ans.downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    def inspect
      "<#{self.class}>"
    end

  end

end
end

