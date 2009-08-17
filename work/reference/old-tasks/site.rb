module Reap

  class Project

    # Install via project's install/setup script.
    #
    # TODO: Remove special reap options from command line.

    def site_install
      script = glob("setup.rb,install.rb,task/setup,task/install").first
      if script
        sh "#{script} #{ARGV.join(' ')}"
      else
        abort "Project needs an install/setup script."
      end
    end

    # TODO: Create uninstall task.

    def site_uninstall
      abort "Not yet implemented."
    end

  end

end

