require 'fileutils'
require 'open-uri'
require 'openssl'
require 'tmpdir'
require 'enumerator'

require 'ostruct'
require 'httpclient'

#require 'facets' #/hash/rekey'
require 'facets/kernel/ask'
require 'facets/module/alias_accessor'
require 'facets/hash/rekey'

require 'pom/metadata'

module Reap
module Plugins

  class SupportService
    attr_accessor :dryrun
    attr_accessor :verbose
    attr_accessor :quiet
    attr_accessor :trace
    attr_accessor :debug
    attr_accessor :force
    attr_accessor :metadata  # get this from Reap

    def quiet?   ; @quiet   ; end
    def verbose? ; @verbose ; end
    def force?   ; @force   ; end
    def dryrun?  ; @dryrun  ; end
    def trace?   ; @trace   ; end
    def debug?   ; @debug   ; end

    # TODO: Can we get this from Reap?
    #def metadata
    #  @metadata ||= Pom::Metadata.new
    #end

   private

    def initialize(options)
      initialize_defaults
      options.each do |k,v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
      yield(self) if block_given?
    end

    #
    def initialize_defaults
    end

    # TODO: replace with facets/string/unfold ?
    def unfold_paragraphs(string)
      blank = false
      text  = ''
      string.split(/\n/).each do |line|
        if /\S/ !~ line
          text << "\n\n"
          blank = true
        else
          if /^(\s+|[*])/ =~ line
            text << (line.rstrip + "\n")
          else
            text << (line.rstrip + " ")
          end
          blank = false
        end
      end
      return text
    end


    #
    def mkdir_p(dir)
      fu.mkdir_p(dir)
    end

    #
    def fu
      if dryrun?
        FileUtils::DryRun
      else
        FileUtils
      end
    end

  end

  #def rubyforge(options={})
  #  opts = config.rubyforge || {}
  #  opts = opts.update(options)
  #  Rubyforge.new(self, opts)
  #end

  # = Rubyforge
  #
  # Interface with the RubyForge hosting service.
  # Supports the following tasks:
  #
  # * release  - Upload release packages
  # * publish  - Publish website
  # * announce - Post news announcement
  # * touch    - Test connection

  class RubyforgeREST < SupportService

    #register('rubyforge', 'rubyforge.org')
    #service_action :publish  => :deploy
    #service_action :release  => :deploy
    #service_action :announce => :deploy

    #service_action :touch

    #HOME    = ENV["HOME"] || ENV["HOMEPATH"] || File.expand_path("~")
    DOMAIN     = "rubyforge.org"
    COOKIEJAR  = File::join(Dir.tmpdir, 'reap', 'cookie.dat')
    REPORT     = /<h\d><span style="color:red">(.*?)<\/span><\/h\d>/

    # Project unixname.
    attr_accessor :project

    #
    alias_accessor :unixname, :project

    # Project's group id number.
    attr_accessor :group_id

    alias_accessor :group   , :group_id
    alias_accessor :groupid , :group_id

    # Username for project account.
    attr_accessor :username

    # Password for project account.
    attr_accessor :password

    #
    #attr_accessor :package

    #
    #attr_accessor :version

    #
    attr_accessor :domain

    #
    attr_accessor :dryrun

    #
    attr_accessor :quiet

    #
    attr_accessor :verbose

    private

    #
    def initialize(options={})
      super

      @project   = options[:project] || options[:unixname] || metadata.project
      #@version  = metadata.version

      @username = options[:username] || ENV['RUBYFORGE_USERNAME']
      @password = options[:password] || ENV['RUBYFORGE_PASSWORD']

      @domain   = DOMAIN

      options.each do |k,v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end

      raise "missing project name in #{self.class.name}" unless project
      #raise "missing domain in #{self.class.name}" unless domain

      FileUtils.mkdir_p(File.dirname(COOKIEJAR))

      @package_ids = {}
      @release_ids = {}
      @file_ids    = {}
    end

    public

    def dryrun?  ; @dryrun   ; end
    def quiet?   ; @quiet    ; end
    def verbose? ; @verbose  ; end

    # New RubyForge object.
    #
    #def initialize(project, options={})
    #end

    # URI = http:// + domain name
    #
    # TODO: Deal with https, and possible other protocols too.

    def uri
      @uri ||= URI.parse("http://" + domain)
    end

    #
    def cookie_jar
      COOKIEJAR
    end

    public

    # Website location on server.
    def siteroot
      "/var/www/gforge-projects"
    end

    # What commands does this host support.
    #def commands
    #  %w{ touch release publish post }
    #end


    # Login to website.

    def login # :yield:
      load_project_cached

      page = uri + "/account/login.php"
      page.scheme = 'https'
      page = URI.parse(page.to_s) # set SSL port correctly

      form = {
        "return_to"      => "",
        "form_loginname" => username,
        "form_pw"        => password,
        "login"          => "Login with SSL"
      }
      html = http_post(page, form)

      if not html[/Personal Page/]
        puts "Login failed."
        re1 = Regexp.escape(%{<h2 style="color:red">})
        re2 = Regexp.escape(%{</h2>})
        html[/#{re1}(.*?)#{re2}/]
        raise $1
      else
        @printed_project_name ||= (puts "Project: #{project}"; true)
      end

      if block_given?
        begin
          yield
        ensure
          logout
        end
      end
    end

    # Logout of website.

    def logout
      page = "/account/logout.php"
      form = {}
      http_post(page, form)
    end

    # Touch base with server -- login and logout.

    def touch(options={})
      login
      puts "Group ID: #{group_id}"
      puts "Login/Logout successful."
      logout
    end

    # Upload release packages to hosting service.
    #
    # This task releases files to RubyForge --it should work with other
    # GForge instaces or SourceForge clones too.
    #
    # While defaults are nice, you may want a little more control. You can
    # specify additional attributes:
    #
    #     files          package files to release
    #                    (by default searches pack/ and pkg/ for know package types)
    #     exclude        Package formats to exclude from files.
    #                    (from those created by pack)
    #     project        Project unixname on host
    #     package        Package to which this release belongs (defaults to project)
    #     release        Release name (default is version number)
    #     version        Version of release
    #     date           Date of release (defaults to Time.now)
    #     processor      Processor/Architecture (any, i386, PPC, etc.)
    #     private        Is a private release? (defaults to false)
    #
    # Rubyforge release also take two documentation elements.
    #
    #     changes        Change log text
    #     notes          Release notes text
    #
    # The release option can be a template by using %s in the
    # string. The version number of your project will be sub'd
    # in for the %s. This saves you from having to update
    # the release name before every release.
    #
    #--
    # What about releasing a pacman PKGBUILD?
    #++

    def release(options)
      options   = options.rekey

      unixname  = self.project

      package   = options[:package] || metadata.package
      version   = options[:version] || metadata.version

      date      = options[:date] || Time::now.strftime('%Y-%m-%d %H:%M')

      changes   = options[:changes]
      notes     = options[:notes]

      release   = options[:release] || version

      files     = options[:files] || options[:file] || []

      #store     = options[:store]     || 'pkg'

      processor = options[:processor] || 'Any'

      is_public = !options[:private]

      #raise ArgumentError, "missing project" unless project
      raise ArgumentError, "missing package" unless package
      raise ArgumentError, "missing release" unless release

      # sub in for version if %s is used in release name.
      release = release % version

      release_notes   = notes
      release_changes = changes

      # Gather package files to release.
      if files.empty?
        files = find_packages(version)
      else
        files = files.map do |file|
          if File.directory?(file)
            find_packages(version, file)
          else
            file
          end
        end
        files = files.flatten
      end
      files = files.select{ |f| File.file?(f) }

      abort "No package files." if files.empty?

      files.each do |file|
        abort "Not a file -- #{file}" unless File.exist?(file)
        puts "Release file: #{File.basename(file)}"
      end

      # which package types
      #rtypes = [ 'tgz', 'tbz', 'tar.gz', 'tar.bz2', 'deb', 'gem', 'ebuild', 'zip' ]
      #rtypes -= exclude
      #rtypes = rtypes.collect{ |rt| Regexp.escape( rt ) }
      #re_rtypes = Regexp.new('[.](' << rtypes.join('|') << ')$')

      puts "Releasing #{package} #{release} in #{project} project..." #unless options['quiet']

      login do

        raise ArgumentError, "missing group_id" unless group_id

        unless package_id = package?(package)
          if dryrun?
            puts "Package '#{package}' does not exist."
            puts "Create package #{package}."
            abort "Cannot continue in dryrun mode."
          else
            #unless options['force']
            q = "Package '#{package}' does not exist. Create?"
            a = ask(q, 'yN')
            abort "Task canceled." unless ['y', 'yes', 'okay'].include?(a.downcase)
            #end
            puts "Creating package #{package}..."
            create_package(package, is_public)
            unless package_id = package?(package)
              raise "Package creation failed."
            end
          end
        end
        if release_id = release?(release, package_id)
          #unless options[:force]
          if dryrun?
            puts "Release #{release} already exists."
          else
            q = "Release #{release} already exists. Re-release?"
            a = ask(q, 'yN')
            abort "Task canceled." unless ['y', 'yes', 'okay'].include?(a.downcase)
            #puts "Use -f option to force re-release."
            #return
          end
          files.each do |file|
            fname = File.basename(file)
            if file_id = file?(fname, package)
              if dryrun?
                puts "Remove file #{fname}."
              else
                puts "Removing file #{fname}..."
                remove_file(file_id, release_id, package_id)
              end
            end
            if dryrun?
              puts "Add file #{fname}."
            else
              puts "Adding file #{fname}..."
              add_file(file, release_id, package_id, processor)
            end
          end
        else
          if dryrun?
            puts "Add release #{release}."
          else
            puts "Adding release #{release}..."
            add_release(release, package_id, files,
              :processor       => processor,
              :release_date    => date,
              :release_changes => release_changes,
              :release_notes   => release_notes,
              :preformatted    => '1'
            )
            unless release_id = release?(release, package_id)
              raise "Release creation failed."
            end
          end
          #files.each do |file|
          #  puts "Added file #{File.basename(file)}."
          #end
        end
      end
      puts "Release complete!" unless dryrun?
    end

    PACKAGE_STORES = %w{pack pkg .cache/pkg}

    #
    def find_packages(version, store=PACKAGE_STORES)
      stores = '{' + [store].flatten.join(',') + '}'
      #files = Dir.glob(File.join(store,"#{name}-#{version}*"))
      files = Dir[File.join(stores, '*')].select do |file|
        /#{version}[.]/ =~ file
      end
      files = files.select{ |f| File.file?(f) }
      files
    end

    # Publish documents to website.
    #
    # === Options
    #
    #   sitemap   hash of local-path => remote-path
    #   filter    path to custom rsync filter file (generally not needed)
    #   delete    delete files on remote end that don't exist on local end [false]
    #   optargs   string of optional arguments to pass to rsync command line tool
    #
    # TODO: Allow sitemap to handle single files (?)
    #       This requires adjusting filter system though.
    #
    def publish(options={})
      options = options.rekey(&:to_s)

      raise "no username" unless username

      sitemap = options['sitemap'] #|| metadata.sitemap
      filter  = options['filter']
      delete  = options['delete']
      optargs = options['optargs']

      #quiet   = options['quiet']   || !verbose? #quiet?
      #verbose = options['verbose'] || verbose?
      #dryrun  = %w{dryrun noharm pretend}.any?{ |x| options[x] } || dryrun?

      case sitemap
      when Hash
      when Array
        sitemap.inject({}) do |h, (s, d)|
          h[s] = d; h
        end
      else
        sitemap = { sitemap.to_s => '.' }
      end

      sitemap.each do |from, to|
        if !File.directory?(from)
          raise ArgumentError, "Non-existant publishing directory -- #{from}."
        end
      end

      sitemap.each do |source, subdir|
        if subdir and subdir != '.'
          destination = File.join(project, subdir)
        else
          destination = project
        end

        dir = source.to_s.chomp('/') + '/'
        url = "#{username}@rubyforge.org:/var/www/gforge-projects/#{destination}"

        op = ["-rLvz"]  # maybe -p ?
        op << "-n"          if dryrun?
        op << "-v"          if verbose?
        op << "-q"          if not verbose?
        op << "--progress"  if not quiet?
        op << "--del-after" if delete
        op << optargs       if optargs

        # custom filter
        op << "--filter='. #{filter}'" if filter

        # create special rubyforge filter (.rsync-filter), if needed.
        create_rsync_filter(source)

        # per dir-merge filter
        op << "--filter=': .rsync-filter'"

        op = op.flatten + [dir, url]

        cmd = "rsync " + op.join(' ')  # "rsync #{op.to_params}"

        # rsync supports a dryrun mode. let it through?
        #if dryrun?
        #  puts cmd
        #else
          system cmd  #UploadUtils.rsync(options)
        #end
      end
    end

  private

    #
    def create_rsync_filter(source)
      protect   = %w{usage statcvs statsvn robot.txt robots.txt wiki}
      exclude   = %w{.svn .gitignore}

      rsync_file = File.join(source,'.rsync-filter')
      unless FileTest.file?(rsync_file)
        File.open(rsync_file, 'w') do |f|
          exclude.each{|e| f << "- #{e}\n"}
          protect.each{|e| f << "P #{e}\n"}
        end
      end

      #protect.to_list.each do |x|
      #  s = x[0,1]
      #  x = x[1..-1] if s == '-' or s == '+'
      #  s  == '-' ? protect.delete(x) : protect << x
      #end

      #exclude.to_list.each do |x|
      #  s = x[0,1]
      #  x = x[1..-1] if s == '-' or s == '+'
      #  s  == '-' ? exclude.delete(x) : exclude << x
      #end
    end

  public

    # Submit a news item.

    def announce(options)
      options = options.rekey

      if file = options[:file]
        text = File.read(file).strip
        i = text.index("\n")
        subject = text[0...i].strip
        message = text[i..-1].strip
      else
        subject = options[:subject] || "Announcing #{project}!"
        message = options[:message] || options[:body]
      end

      if dryrun?
        puts "announce-rubyforge: #{subject}"
      else
        post_news(subject, message)
        puts "News item posted!"
      end
    end

    private

    # HTTP POST transaction.

    def http_post(page, form, extheader={})
      client = HTTPClient::new ENV["HTTP_PROXY"]
      client.debug_dev = STDERR if ENV["REAP_DEBUG"] || $DEBUG
      client.set_cookie_store(cookie_jar)
      client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # HACK to fix http-client redirect bug/feature
      client.redirect_uri_callback = lambda do |uri, res|
        page = res.header['location'].first
        page =~ %r/http/ ? page : @uri + page
      end

      uri = @uri + page
      if $DEBUG then
        puts "POST #{uri.inspect}"
        puts "#{form.inspect}"
        puts "#{extheader.inspect}" unless extheader.empty?
        puts
      end

      response = client.post_content uri, form, extheader

      if response[REPORT]
        puts "(" + $1 + ")"
      end

      client.save_cookie_store

      return response
    end

    #

    def load_project_cached
      @load_project_cache ||= load_project
    end

    # Loads information for project: group_id, package_ids and release_ids.

    def load_project
      html = URI.parse("http://#{domain}/projects/#{project}/index.html").read

      group_id = html[/(frs|tracker)\/\?group_id=\d+/][/\d+/].to_i

      self.group_id = group_id

      if $DEBUG
        puts "GROUP_ID = #{group_id}"
      end

      html = URI.parse("http://rubyforge.org/frs/?group_id=#{group_id}").read

      package = nil
      html.scan(/<h3>[^<]+|release_id=\d+">[^>]+|filemodule_id=\d+/).each do |s|
        case s
        when /<h3>([^<]+)/ then
          package = $1.strip
        when /filemodule_id=(\d+)/ then
          @package_ids[package] = $1.to_i
        when /release_id=(\d+)">([^<]+)/ then
          package_id = @package_ids[package]
          @release_ids[[package_id,$2]] = $1.to_i
        end
      end

      if $DEBUG
        p @package_ids, @release_ids
      end
    end

    # Returns password. If not already set, will ask for it.
    #
    def password
      @password ||= ENV['RUBYFORGE_PASSWORD']
      @password ||= (
        $stdout << "Password for #{username}: "
        $stdout.flush
        until inp = $stdin.gets ; sleep 1 ; end ; puts
        inp.strip
      )
    end

    # Package exists? Returns package-id number.
    #
    def package?(package_name)
      id = @package_ids[package_name]
      return id if id

      package_id = nil

      page = "/frs/"

      form = {
        "group_id" => group_id
      }
      scrape = http_post(page, form)

      restr = ''
      restr << Regexp.escape( package_name )
      restr << '\s*'
      restr << Regexp.escape( '<a href="/frs/monitor.php?filemodule_id=' )
      restr << '(\d+)'
      restr << Regexp.escape( %{&group_id=#{group_id}} )
      re = Regexp.new( restr )

      md = re.match( scrape )
      if md
        package_id = md[1]
      end

      @package_ids[package_name] = package_id
    end

    # Create a new package.

    def create_package( package_name, is_public=true )
      page = "/frs/admin/index.php"

      form = {
        "func"         => "add_package",
        "group_id"     => group_id,
        "package_name" => package_name,
        "is_public"    => (is_public ? 1 : 0),
        "submit"       => "Create This Package"
      }

      http_post(page, form)
    end

    # Delete package.

    def delete_package(package_id)
      page = "/frs/admin/index.php"

      form = {
        "func"        => "delete_package",
        "group_id"    => group_id,
        "package_id"  => package_id,
        "sure"        => "1",
        "really_sure" => "1",
        "submit"      => "Delete",
      }

      http_post(page, form)
    end

    # Release exits? Returns release-id number.

    def release?(release_name, package_id)
      id = @release_ids[[release_name,package_id]]
      return id if id

      release_id = nil

      page = "/frs/admin/showreleases.php"

      form = {
        "package_id" => package_id,
        "group_id"   => group_id
      }
      scrape = http_post( page, form )

      restr = ''
      restr << Regexp.escape( %{"editrelease.php?group_id=#{group_id}} )
      restr << Regexp.escape( %{&amp;package_id=#{package_id}} )
      restr << Regexp.escape( %{&amp;release_id=} )
      restr << '(\d+)'
      restr << Regexp.escape( %{">#{release_name}} )
      re = Regexp.new( restr )

      md = re.match( scrape )
      if md
        release_id = md[1]
      end

      @release_ids[[release_name,package_id]] = release_id
    end

    # Add a new release.

    def add_release(release_name, package_id, *files)
      page = "/frs/admin/qrs.php"

      options = (Hash===files.last ? files.pop : {}).rekey
      files = files.flatten

      processor       = options[:processor]
      release_date    = options[:release_date]
      release_changes = options[:release_changes]
      release_notes   = options[:release_notes]

      release_date ||= Time::now.strftime("%Y-%m-%d %H:%M")

      file = files.shift
      puts "Adding file #{File.basename(file)}..."
      userfile = open(file, 'rb')

      type_id = userfile.path[%r|\.[^\./]+$|]
      type_id = FILETYPES[type_id]
      processor_id = PROCESSORS[processor.downcase]

      preformatted = '1'

      form = {
        "group_id"        => group_id,
        "package_id"      => package_id,
        "release_name"    => release_name,
        "release_date"    => release_date,
        "type_id"         => type_id,
        "processor_id"    => processor_id,
        "release_notes"   => release_notes,
        "release_changes" => release_changes,
        "preformatted"    => preformatted,
        "userfile"        => userfile,
        "submit"          => "Release File"
      }

      boundary = Array::new(8){ "%2.2d" % rand(42) }.join('__')
      boundary = "multipart/form-data; boundary=___#{ boundary }___"

      html = http_post(page, form, 'content-type' => boundary)

      release_id = html[/release_id=\d+/][/\d+/].to_i
      puts "RELEASE ID = #{release_id}" if $DEBUG

      files.each do |file|
        puts "Adding file #{File.basename(file)}..."
        add_file(file, release_id, package_id, processor)
      end

      release_id
    end

    # File exists?
    #
    # NOTE this is a bit fragile. If two releases have the same exact
    # file name in them there could be a problem --that's probably not
    # likely, but I can't yet rule it out.
    #
    # TODO Remove package argument, it is no longer needed.

    def file?(file, package)
      id = @file_ids[[file, package]]
      return id if id

      file_id = nil

      page = "/frs/"

      form = {
        "group_id"   => group_id
      }
      scrape = http_post(page, form)

      restr = ''
      #restr << Regexp.escape( package )
      #restr << '\s*'
      restr << Regexp.escape( '<a href="/frs/download.php/' )
      restr << '(\d+)'
      restr << Regexp.escape( %{/#{file}} )
      re = Regexp.new(restr)

      md = re.match(scrape)
      if md
        file_id = md[1]
      end

      @file_ids[[file, package]] = file_id
    end

    # Remove file from release.

    def remove_file(file_id, release_id, package_id)
      page="/frs/admin/editrelease.php"

      form = {
        "group_id"     => group_id,
        "package_id"   => package_id,
        "release_id"   => release_id,
        "file_id"      => file_id,
        "step3"        => "Delete File",
        "im_sure"      => '1',
        "submit"       => "Delete File "
      }

      http_post(page, form)
    end

    #
    # Add file to release.
    #

    def add_file(file, release_id, package_id, processor=nil)
      page = '/frs/admin/editrelease.php'

      userfile = open file, 'rb'

      type_id      = userfile.path[%r|\.[^\./]+$|]
      type_id      = FILETYPES[type_id]
      processor_id = PROCESSORS[processor.downcase]

      form = {
        "step2"        => '1',
        "group_id"     => group_id,
        "package_id"   => package_id,
        "release_id"   => release_id,
        "userfile"     => userfile,
        "type_id"      => type_id,
        "processor_id" => processor_id,
        "submit"       => "Add This File"
      }

      boundary = Array::new(8){ "%2.2d" % rand(42) }.join('__')
      boundary = "multipart/form-data; boundary=___#{ boundary }___"

      http_post(page, form, 'content-type' => boundary)
    end

    # Posts news item to +group_id+ (can be name) with +subject+ and +body+

    def post_news(subject, body)
      page = "/news/submit.php"

      subject % [project, version]

      form = {
        "group_id"     => group_id,
        "post_changes" => "y",
        "summary"      => subject,
        "details"      => body,
        "submit"       => "Submit"
      }

      login do
        http_post(page, form)
      end
    end

    # Generic announce confirmation.
# "Release to #{self.class.basename.downcase}?"
    def confirm?(message, options={})
      return true if force?
      ans = ask(message, "yN")
      case ans.downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    DEFAULT_ANNOUNCEMENT = "doc/ann{,ounce}{.txt,.rdoc}"

    #ans = ask("Announce to #{self.class.basename.downcase}?", "yN")

    #
    def announcement(file=nil)
      template = file || DEFAULT_ANNOUNCEMENT
      project.generate('templates'=>template)
      file = Dir.glob(template, File::FNM_CASEFOLD).first
      text = File.read(file)
      text = unfold_paragraphs(text)
      text
    end


    # Constant for file types accepted by Rubyforge

    FILETYPES = {
      ".deb"         => 1000,
      ".rpm"         => 2000,
      ".zip"         => 3000,
      ".bz2"         => 3100,
      ".gz"          => 3110,
      ".src.zip"     => 5000,
      ".src.bz2"     => 5010,
      ".src.tar.bz2" => 5010,
      ".src.gz"      => 5020,
      ".src.tar.gz"  => 5020,
      ".src.rpm"     => 5100,
      ".src"         => 5900,
      ".jpg"         => 8000,
      ".txt"         => 8100,
      ".text"        => 8100,
      ".htm"         => 8200,
      ".html"        => 8200,
      ".pdf"         => 8300,
      ".oth"         => 9999,
      ".ebuild"      => 1300,
      ".exe"         => 1100,
      ".dmg"         => 1200,
      ".tar.gz"      => 3110,
      ".tgz"         => 3110,
      ".gem"         => 1400,
      ".pgp"         => 8150,
      ".sig"         => 8150
    }

    # Constant for processor types accepted by Rubyforge

    PROCESSORS = {
      "i386"       => 1000,
      "IA64"       => 6000,
      "Alpha"      => 7000,
      "Any"        => 8000,
      "PPC"        => 2000,
      "MIPS"       => 3000,
      "Sparc"      => 4000,
      "UltraSparc" => 5000,
      "Other"      => 9999,

      "i386"       => 1000,
      "ia64"       => 6000,
      "alpha"      => 7000,
      "any"        => 8000,
      "ppc"        => 2000,
      "mips"       => 3000,
      "sparc"      => 4000,
      "ultrasparc" => 5000,
      "other"      => 9999,

      "all"        => 8000,
      nil          => 8000
    }

  end

end
end
