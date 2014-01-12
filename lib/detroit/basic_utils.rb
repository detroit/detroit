module Detroit

  ##
  # Common utility methods included in all tools.
  #
  module BasicUtils

    # Glob for finding root of a project.
    def root_pattern
      "{.index,.git,.hg,.svn,_darcs}"
    end
 
    # Project root directory.
    def root
      @root ||= (
        path = nil
        home = File.expand_path('~')

        while dir != home && dir != '/'
          if Dir[root_pattern].first
            path = dir
            break
          end
          dir = File.dirname(dir)
        end

        Pathname.new(path || Dir.pwd)
      )
    end

    # Configuration.
    def config
      @config ||= Config.new(root)
    end

    #
    def naming_policy
      @naming_policy ||= (
        if config.naming_policy
          Array(config.naming_policy)
        else
          ['down', 'ext']
        end
      )
    end

    #
    def apply_naming_policy(name, ext)
      naming_policy.each do |policy|
        case policy.to_s
        when /^low/, /^down/
          name = name.downcase
        when /^up/
          name = name.upcase
        when /^cap/
          name = name.capitalize
        when /^ext/
          name = name + ".#{ext}"
        end
      end
      name
    end

  end

end
