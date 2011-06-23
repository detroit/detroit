module Detroit

  #
  require 'pom'

  #
  module ProjectUtils

    # Common access to project.
    def self.project(path=Dir.pwd)
      if root = ::POM::Project.root(path)
        @@projects ||= {}
        @@projects[root] ||= ::POM::Project.new(root)
      else
        nil # ?
      end
    end

    #
    def project(path=Dir.pwd)
      @project ||= ProjectUtils.project(path)
    end

    # Set project manutally.
    def project=(proj)
      @project = proj
    end

    #
    def metadata
      project.metadata
    end

    #
    def root
      project.root
    end

  end

end
