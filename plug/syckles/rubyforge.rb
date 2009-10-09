require File.dirname(__FILE__) + '/rubyforge/rubyforge.rb'

module Syckles

  # = Rubyforge Plugin
  #
  # Interface with the RubyForge project hosting services.
  # This plugin will upload release packages, publish your
  # website via rsync, and make new announcements.
  #
  # This plugin can run automatically if the POM repository
  # entry references 'rubyforge.org'.
  #
  # Pleae note that making news announcements is currently
  # not functional.
  #
  # TODO: Use new REST API.
  #
  # TODO: Check Rubyforge admin config to see which Rubyforge 
  # services are being used and adjust actions for this plugin
  # accordingly.
  #
  class Rubyforge < Service

    #pipeline :main, :publish  => :release,
    #                :release  => :release,
    #                :announce => :promote
    #pipeline :site, :publish  => :release

    cycle :main, :release do
      release
      publish
    end

    cycle :main, :promote do
      announce
    end

    cycle :site, :release do
      publish
    end

    # Rubyforge will be available automatically if the POM repository
    # entry indicates the use of Rubyforge.
    autorun do |project|
      /rubyforge.org/ =~ project.metadata.repository
    end

    #available do |project|
    #  begin
    #    require 'forge/rubyforge'
    #    true
    #  #rescue LoadError
    #  #  false
    #  end
    #end

    HOME    = ENV["HOME"] || ENV["HOMEPATH"] || File.expand_path("~")
    REPORT  = /<h\d><span style="color:red">(.*?)<\/span><\/h\d>/
    #DOMAIN = "rubyforge.org"

    # Project unixname.
    attr_accessor :unixname

    # Project's group id number.
    attr_accessor :group

    alias_accessor :groupid,  :group
    alias_accessor :group_id, :group

    # Username for project account.
    attr_accessor :username

    # Password for project account.
    attr_accessor :password

    # Package name.
    attr_accessor :package

    # Package version.
    attr_accessor :version

    # File that holds the current release notes.
    attr_accessor :notelog

    # File that hold the current change log.
    # If not provided then the changelog will
    # taken from the bottom of the notelog
    # split on a '---' or '####' marker.
    attr_accessor :changelog

    # Release name. Use %s for inserting the version number.
    #
    #   Eg. foo-%s
    #
    # becomes
    #
    #   foo-1.0.0
    #
    # By default this is just "%s".

    attr_accessor :release_template

    # Is this a private release?
    attr_accessor :private_release

    # Directory to publish. Leave empty
    # for for defaults (web, site, website, doc or doc/rdoc).
    # Or use a Hash to create a publishing map. Eg.
    #
    #   service: Rubyforge
    #   site_map:
    #     site    : .
    #     doc/rdoc: rdoc
    #
    attr_accessor :site_map

    # Common alias for #site_map.
    alias_accessor :sitemap, :site_map

    # Should the site be published wholesale, removing
    # any other content present at the upload destination?
    # Note, this is the same as setting +site_rsync+ to '--del-after'.
    #
    attr_accessor :site_delete

    # Used to specify any additional rsync options.
    attr_accessor :site_rsync

    private

      def initialize_defaults
        @unixname = metadata.project
        @username = ENV['RUBYFORGE_USERNAME']
        @password = ENV['RUBYFORGE_PASSWORD']

        @package  = metadata.package
        @version  = metadata.version

        @release_template = "%s"

        #@changelog = Dir.glob('{history,changelog,changes}{,.txt}', File::FNM_CASEFOLD).first

        @notelog   = Dir.glob('{release,news,notes,notice}{,.txt}', File::FNM_CASEFOLD).first
        @changelog = nil

        @site_map  = metadata.sitemap

        #options = {}
        #options[:unixname] = metadata.project
        #options[:version]  = metadata.version
        #options[:username] = ENV['RUBYFORGE_USERNAME']
        #options[:password] = ENV['RUBYFORGE_PASSWORD']

        #options[:dryrun]   = dryrun?
        #options[:quiet]    = quiet?
        #options[:verbose]  = verbose?

        #@rubyforge = Support::Rubyforge.new(metadata.name, options)
      end

      #
      def rubyforge
        @rubyforge ||= (
          options = {}
          options[:unixname] = unixname
          options[:username] = username
          options[:password] = password
          options[:group_id] = group_id

          options[:package]  = package
          options[:version]  = version

          options[:dryrun]   = dryrun?
          options[:quiet]    = quiet?
          options[:verbose]  = verbose?

          options[:metadata] = metadata

          RubyforgeREST.new(options)
        )
      end

    public

    #
    #def release
    #  release_package
    #  release_website
    #end

    # Release packages to Rubyforge.
    #
    def release
      options = {}
      options[:release]   = release_template % [version]
      options[:is_public] = !private_release

      if notelog && test(?f, notelog)
        options[:notes] = File.read(notelog)
      else
        options[:notes] = project.history.release.notes
      end

      if changelog && test(?f, changelog)
        options[:changes] = File.read(changelog)
      else
        options[:changes] = project.history.release.changes
      end

      #else
      #  if notelog
      #    notes = File.read(notelog)
      #    index = notes.index(/^(###|===|---)/m)
      #    if index
      #      changes = notes[index..-1]
      #      notes   = notes[0...index]
      #    else
      #      changes = ''
      #    end
      #    options[:notes]   = notes
      #    options[:changes] = changes
      #  end
      #end

      options[:date] = Time::now.strftime('%Y-%m-%d %H:%M')

      # collect package files
      files = Dir.glob(project.pack / "*-#{version}.*")

      packages = {}

      files.each do |file|
        name = file.chomp(File.extname(file))
        name = name.chomp('.tar') # in case of 'tar.gz' or 'tar.bz2'
        name = name.sub(/-#{version}$/,'')
        name = File.basename(name)
        packages[name] ||= []
        packages[name] << file
      end

      packages.each do |name, files|
        options[:package]   = name
        options[:files]     = files
        options[:processor] = 'Any' # TODO: Correlate processor to platform

        rfiles = files.collect{ |f| Pathname.new(f).relative_path_from(project.root) }
        if dryrun?
          status "rubyforge release --processor=#{options[:processor]} #{rfiles.join(' ')}"
        else
          #status "rubyforge announce #{options.to_console}"
          rubyforge.release(options)
        end
      end
    end

    DEFAULT_SITE = '{site,web,website,doc,doc/rdoc}/index.*'

    # Publish website to Rubyforge.
    #
    # By deafult plublish looks in site/, web/, website/,
    # doc/ and doc/rdoc, in that order, for an index.* file,
    # and uses that diretory as the publishing source.
    #
    # If not already present, it will create a default .rsync-filter
    # file in the source directory, which is used to omit certain
    # files from publishing and/or protect files from removal at
    # the remote end. (see 'man rsync').
    #
    def publish
      options = {}

      sitemap = self.sitemap

      if !sitemap
        index  = project.root.glob_first(DEFAULT_SITE)
        source = File.dirname(index)
        #unless src
        #  if src = project.root.glob_first('doc')
        #    unless src.glob_first('index.{html,xml,rhtml}')
        #      src = project.root.glob_first('doc/rdoc')
        #    end
        #  end
        #end
        sitemap = { source => '.' }
      end

      sitemap.each do |src, dest|
        unless src && File.directory?(src)
          report "Can't publish. Not a directory to publish (#{src})."
          return
        end
      end

      filter = project.config.glob_first('.rsync-filter')

      options['filter']  = filter if filter
      options['sitemap'] = sitemap
      options['quiet']   = quiet?
      options['verbose'] = verbose?
      options['delete']  = site_delete
      options['argv']    = site_rsync

      report "Uploading website:\n" +
             sitemap.map{ |f,t| "  #{f.sub(Dir.pwd+'/','')} => #{t}" }.join("\n")

      #if dryrun?
      #  report "rubyforge publish #{options.to_console}"
      #else
        #report "rubyforge announce #{options.to_console}"
        rubyforge.publish(options)
      #end
    end

    # Make an announcement to Rubyforge.
    #
    def announce
      options = {}
      options[:subject] = "#{metadata.title} v#{version}"
      options[:message] = announcement
      if dryrun?
        status "rubyforge announce '#{options[:subject]}'"
      else
        #status "rubyforge announce #{options.to_console}"
        rubyforge.announce(options)
      end
    end

    #
    #
    def touch
      rubyforge.touch
    end

    # Generic confirmation.
    #
    def confirm?(action, options={})
      return true if force?
      ans = ask("#{action.to_s.capitalize} to #{self.class.basename.downcase}?", "yN")
      case ans.downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    #
    def announcement
      project.announcement
    end

=begin
    #
    README = "readme{,.txt}"

    #
    RELEASE = "{release,news,notes}{,.txt}"

    # Create an announcement.
    #
    def announcement(file=nil, options={})
      header = options[:header]

      if file = Dir.glob(file, File::FNM_CASEFOLD).first
        ann = File.read(file)
      else
        readme_file  = Dir.glob(README, File::FNM_CASEFOLD).first
        release_file = Dir.glob(RELEASE, File::FNM_CASEFOLD).first

        ann = []

        if readme_file
          readme = File.read(readme_file).strip
          if release_file
            # read release file and strip
            release = File.read(release_file).strip
            # remove header if release file has one
            release.sub!(/^.*?$/, '') if release[0,1] == '='
            # sub in for release where the readme referes to it
            readme.sub!(/^Please see (the)? RELEASE file.*?$/, release.strip)
          end
          ann << readme
        else
          if header and not release_file
            ann << "#{metadata.title} #{metadata.version} has been released."
            ann << ''
            ann << "  #{metadata.homepage}"
            ann << ''
            ann << "#{metadata.abstract}"
            ann << ''
          end
          if release_file
            ann << File.read(release_file)
          end
        end
        ann = ann.join("\n")
      end
      ann.unfold_paragraphs
    end
=end

    #def announce_confirm?(options={})
    #  return true if force?
    #  ans = ask("Announce to #{self.class.basename.downcase}?", "yN")
    #  case ans.downcase
    #  when 'y', 'yes'
    #    true
    #  else
    #    false
    #  end
    #end

    # Generic announce confirmation.

    #def release_confirm?(options={})
    #  return true if force?
    #  ans = ask("Release to #{self.class.basename.downcase}?", "yN")
    #  case ans.downcase
    #  when 'y', 'yes'
    #    true
    #  else
    #    false
    #  end
    #end
  end

end

