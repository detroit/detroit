require 'time'

module Reap

  class Project

    class Metadata

      # = Version
      #
      # VersionStamp access the VERSION stamp
      # file to determine name, version, release date,
      # status and codename of a project.
      #
      # It is used by Metadata which delegates to it.
      class Version

        attr :rootfolder

        attr :stampfile

        attr_accessor :project
        attr_accessor :version
        attr_accessor :status
        attr_accessor :release
        attr_accessor :codename

        ###
        def initialize(rootfolder)
          @rootfolder = rootfolder

          file = rootfolder.glob('VERSION{,.txt}', :casefold).first
          if file 
            parse(File.read(file))
            @stampfile = file
          else
            raise "No version stamp found."
          end
        end

        ###
        def parse(text)
          project, version, status, release, codename = *text.split(/\s+/)
          self.project     = project
          self.version     = version
          self.status      = status
          self.release     = release
          self.codename    = codename
        end

        ###
        def release=(date)
          @release = Time.parse(date)
        end

      end#class VersionStamp

    end#class Metadata

  end#class Project

end#module Reap

