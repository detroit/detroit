require 'reap/service'

module Reap

  # = Subversion
  #
  # Source control system for Subversion.
  #
  # Options are:
  #
  #   repository    Developers URL to repository. Defaults to Rubyforge address.
  #   username      Username. Defaults to ENV['RUBYFORGE_USERNAME'].
  #   protocol      The URL protocol to use. Defaults to "svn+ssh".
  #   prefix        Prefix to use on tag folder. Default is no prefix.
  #   tagpath       Directory to store tags. Defaults to ../tags/.
  #   branchpath    Directory to store branches. Defaults to ../branches/.
  #
  # TODO: Perhaps format prefix, like: 
  #       prefix  = prefix + '_' if prefix && prefix !~ /[_-]$/
  #
  # TODO: tie in Metadata#scm, but probably via project/scm.rb.
  #
  # TODO: Allow for a way to dump the text-based Changelog to standard out. "$stdout" as the filename?
  #
  # TODO: How to apply naming policy from here?
  #
  class Svn < Service

    pipeline :main, :document => :document #, :changelog => :document

    available do |project|
      (project.root + '.svn').directory?
    end

    # TODO: Add tag/archive support.
    #service_action :tag,       :main => :archive
    #service_action :branch (?)

    DEFAULT_TAGPATH    = 'tags'
    DEFAULT_BRANCHPATH = 'branches'
    DEFAULT_PROTOCOL   = 'svn+ssh'

    # Project unixname (for repository).
    attr_accessor :unixname

    # Current version of project.
    attr_accessor :version

    # Developers URL to repository. Defaults to Rubyforge address.
    attr_accessor :repository

    # Username. Defaults to ENV['RUBYFORGE_USERNAME'].
    attr_accessor :username

    # The URL protocol to use. Defaults to "svn+ssh".
    attr_accessor :protocol

    # Prefix to use on tag folder. Default is no prefix.
    attr_accessor :prefix

    # Optional commit message. This is intended for commandline
    # usage. (Use -m for shorthand).
    attr_accessor :message

    # Directory to store tags. Defaults to tags/.
    attr_accessor :tagpath

    # Directory to store branches. Defaults to branches/.
    attr_accessor :branchpath

    # Changelog format (xml or gnu). Default is gnu.
    #attr_accessor :format

    # If set to true will include all commits in public
    # ChangeLog. By default only typed commits are included.
    #
    # TODO: Make types selectable using an array.
    #attr_accessor :all

    #
    def initialize_defaults
      @unixname   = metadata.project
      @version    = metadata.version

      @protocol   = DEFAULT_PROTOCOL
      @tagpath    = DEFAULT_TAGPATH
      @branchpath = DEFAULT_BRANCHPATH

      # fallback default is for rubyforge.org
      @username   = ENV['RUBYFORGE_USERNAME']
      @repository = metadata.repository || "rubyforge.org/var/svn/#{unixname}"

      @format     = 'xml'

      if i = @repository.index('//')
        @repository = @repository[i+2..-1]
      end
    end

    # Developer domain is "username@repository".
    def developer_domain
      "#{username}@#{repository}"
    end

    # Tag current versoin of project. This method routes
    # to the appropriate method for the project's source
    # control manager.
    #
    #   message       Optional commit message. This is intended for commandline
    #                 usage. (Use -m for shorthand).
    #
    # TODO: How should metadata.repository come into play here?
    #
    def tag(options={})
      options = configure_options(options, 'scm-tag', 'scm')

      msg  = options['message'] || options['m']
      name = "#{prefix}#{version}"
      path = tagpath.to_s

      if path == '.' or path.empty?
        url = "#{protocol}://" + File.join(developer_domain, name)
      else
        url = "#{protocol}://" + File.join(developer_domain, path, name)
      end

      if dryrun?
        puts "svn copy . #{url}"
      else
        case ask("Tag: #{url} ? [yN]").strip.downcase
        when 'y', 'yes'
          #sh "svn copy #{protocol}://#{username}@#{repository}/trunk #{url}"
          sh "svn copy . #{url}"
        end
      end
    end

=begin
    # Branch current version of project. This method routes
    # to the appropriate method for the project's source
    # control manager.
    #
    #   message    Optional commit message. This is intended
    #              for commandline usage. (Use -m for shorthand).
    #
    # TODO: How should metadata.repository come into play here?

    def branch(options={})
      options = configure_options(options, 'scm-branch', 'scm')

      msg  = options['message'] || options['m']
      name = "#{prefix}#{version}"
      path = branchpath.to_s

      if path == '.' or path.empty?
        url = "#{protocol}://" + File.join(developer_domain, name)
      else
        url = "#{protocol}://" + File.join(developer_domain, path, name)
      end

      if dryrun?
        puts "svn copy . #{url}"
      else
        case ask("Branch: #{url} ? [yN]").strip.downcase
        when 'y', 'yes'
          #sh "svn copy #{protocol}://#{username}@#{repository}/trunk #{url}"
          sh "svn copy . #{url}"
        end
      end
    end
=end

=begin
    #

    def svn_repository_configuration(options, *entries)
      entries << 'svn'
      options = configure_options(options, *entries)

      options['repository'] ||= metadata.repository
      options['protocol']   ||= 'svn+ssh'
      options['message']    ||= options.delete('m')
      options['tagpath']    ||= 'tags'

      unless repository
        rubyforge   = configuration['rubyforge'] || {}
        projectname = rubyforge['project'] || metadata.name
        options['repository']  = "rubyforge.org/var/svn/#{projectname}"
      end

      if i = options['repository'].index('//')
        options['repository'] = options['repository'][i+2..-1]
      end

      if /rubyforge.org/i =~ options['repository']
        options['username'] ||= ENV['RUBYFORGE_USERNAME']
      end

      return options
    end
=end

=begin
    # Generate changelogs.
    def document
      document_master_changelog
      document_public_changelog
    end

    # TODO: apply_naming_policy ?
    def document_master_changelog
      format = self.format || 'txt'
      #apply_naming_policy('changelog', log_format.downcase)
      file = (project.log + "changelog.#{format}").to_s
      if dryrun?
        puts "svn log > #{file}"
      else
        changelog.save(file, format)
      end
    end

    #
    def document_public_changelog
      if file = project.root.glob_first("{HISTORY,CHANGES}{.txt,}", :casefold)
        #file = (project.root + file).to_s
        if dryrun?
          puts "svn log > #{file}"
        else
          public_changelog = all ? changelog : changelog.typed
          if rels = releases
            public_changelog.save(file.to_s, :rel, rels)
          else
            public_changelog.save(file.to_s, :gnu)
          end
        end
      end
    end

    #
    def releases
      rfile = (project.root + 'meta/releases')
      return nil unless rfile.file?
      r = {}
      rfile.each_line do |line|
        line = line.strip
        next if line.empty?
        name, version, status, date, codename = *parse_version_stamp(line)
        r[date] = version
      end
      return r
    end

    #
    def parse_version_stamp(line)
      name, version, status, date, codename = *line.split(/\s+/)
      date = Time.parse(date)
      return name, version, status, date, codename
    end

    # Save ChangeLog.
    #
    #   changelog  The Changelog object.
    #   file       File to save to.
    #   format     Format to use. Supports 'xml', 'html', or 'txt'.
    #
    # Set either to false to supress creation.
    #def save_changelog(changelog, file, format)
    #  if dryrun?
    #    puts "svn log > #{file}"
    #  else
    #    changelog.save(file, format)
    #    puts "Updated #{relative_from_root(file)}"
    #  end
    #end

    # Access to version control.
    def vcs
      @vcs ||= ProUtils::VCS.new #(self)
    end

    # Get changelog from ProUtils VCS.
    def changelog
      @changelog ||= vcs.changelog
    end

    #
    def relative_from_root(path)
      Pathname.new(path).relative_path_from(project.root)
    end

    #
    #def save(file, txt)
    #  out = Pathname.new(file).relative_path_from(project.root)
    #  mkdir_p(File.dirname(file))
    #  if dryrun?
    #    puts "write #{out}"
    #  else
    #    File.open(file, 'w'){ |f| f << txt }
    #    puts "Updated #{out}"
    #  end
    #end
=end

  end

end

