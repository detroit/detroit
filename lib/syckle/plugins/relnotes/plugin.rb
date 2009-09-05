require 'reap/plugin'

module Reap
module Plugins

  # = Release Log Service
  #
  class ReleaseLog < Plugin

    pipeline :main, :document

    available{ |project| true }

    attr_accessor :output

    #
    def initialize_defaults
      require 'proutils/vclog/vcs'
    end

    # Collect embedded notes.
    #
    # This task scans source code for developer notes and writes to
    # well organized files. This tool can lookup and list TODO, FIXME
    # and other types of labeled comments from source code.
    #
    #   files    Glob(s) of files to search.
    #   labels   Labels to search for. Defaults to [ 'TODO', 'FIXME' ].
    #   output   Output directory. Defaults to log/.
    #
    # TODO: Remove format field, and ultimately use XML as primary format?

    def document
      date_limit = Time.now - 30*24*60*60 # FIXME

      #apply_naming_policy('NEWS', log_format.downcase)

      file = project.root.glob_first("{RELEASE,NOTES,NEWS}{,.txt}", :casefold)
      file = (project.root + 'RELEASE') unless file

      text = changelog.recent_text(date_limit)

      save(file, text)
    end

  private

    def changelog
      project.vcs.changelog
    end

    #def log_recent
    #  @log_recent ||= log.typed
    #end

    #
    def save(file, text)
      text = "### #{Time.now}\n\n#{text}"

      if file.exist?
        content = file.read.strip
      else
        content = ""
      end

      if i = content.index(/^###/m)
        content[i..-1] = text
      else
        content += ("\n\n" + text)
      end
      file_write(file, content)
    end

  end

end
end

