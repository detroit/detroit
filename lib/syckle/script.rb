require 'yaml'
require 'rbconfig'  # replace with facets/rbsystem?
#require 'ostruct'
#require 'tmpdir'

require 'facets/platform'

require 'pom/project'

#require 'syckle/core_ext'
#require 'syckle/log'

require 'syckle/cli'
require 'syckle/io'
require 'syckle/shell'


module Syckle

  # = Syckle Script Domain
  #
  # The DSL class is the heart of Syckle, it provides all the convenece methods
  # that make Syckle services so convenient to write.
  #
  # TODO: Better name?
  #
  class Script < Module

    #
    def initialize(options={})
      extend self

      @project = POM::Project.new(:lookup=>true, :load=>true)

      options.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end

      @cli ||= CLI.new
      @io  ||= IO.new(@cli)

      path = @project.root || Dir.pwd   # TODO: error or pwd ?

      mode = {
        :noop    => @cli.noop?,
        :verbose => @cli.verbose?,
        :quiet   => @cli.quiet?
      }

      @shell = Shell.new(path, mode)
    end

    def force?   ; cli.force?   ; end
    def debug?   ; cli.debug?   ; end
    def quiet?   ; cli.quiet?   ; end
    def noop?    ; cli.noop?    ; end
    def verbose? ; cli.verbose? ; end

    def trace?   ; cli.debug && cli.verbose? ; end
    def dryrun?  ; cli.noop? && cli.verbose? ; end

    # The #cli method provides delagated access to commandline
    # arguments and options via the CLI interface.
    attr_accessor :cli

    # Delagate input/output routines to IO object.
    attr_accessor :io

    # Delagate file operations to Shell.
    attr_accessor :shell

    # POM::Project object.
    attr_reader :project

    # POM::Metadata object, derived from Project.
    def metadata
      project.metadata
    end

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    # Delegate to Shell.
    def method_missing(s, *a, &b)
      if @shell.respond_to?(s)
        @shell.__send__(s, *a, &b)
      else
        if @io.respond_to?(s)
          @io.__send__(s, *a, &b)
        else
          super
        end
      end
    end

    # Load configuration data from a file.
    # Results are cached and and empty Hash is
    # returned if the file is not found.
    #
    # Since they are YAML files, they can optionally
    # end with '.yaml' or '.yml'.
    def configuration(file)
      @configuration ||= {}
      @configuration[file] ||= (
        begin
          configuration!(file)
        rescue LoadError
          Hash.new{ |h,k| h[k] = {} }
        end
      )
    end

    # Load configuration data from a file.
    # The "bang" version will raise an error
    # if file is not found. It also does not
    # cache the results.
    #
    # Since they are YAML files, they can optionally
    # end with '.yaml' or '.yml'.
    def configuration!(file)
      @configuration ||= {}
      patt = file + "{.yml,.yaml,}"
      path = Dir.glob(patt, File::FNM_CASEFOLD).find{ |f| File.file?(f) }
      if path
        # The || {} is in case the file is empty.
        data = YAML::load(File.open(path)) || {}
        @configuration[file] = data
      else
        raise LoadError, "Missing file -- #{path}"
      end
    end

    #
    #
    def naming_policy(*policies)
      if policies.empty?
        @naming_policy ||= ['down', 'ext']
      else
        @naming_policy = policies
      end
    end

    #
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

    # Email function to easily send out an email.
    #
    # Settings:
    #
    #     subject      Subject of email message.
    #     from         Message FROM address [email].
    #     to           Email address to send announcemnt.
    #     server       Email server to route message.
    #     port         Email server's port.
    #     domain       Email server's domain name.
    #     account      Email account name if needed.
    #     password     Password for login..
    #     login        Login type: plain, cram_md5 or login [plain].
    #     secure       Uses TLS security, true or false? [false]
    #     message      Mesage to send -or-
    #     file         File that contains message.
    #
    def email(options)
      emailer = Emailer.new(options.rekey)
      success = emailer.email
      if Exception === success
        puts "Email failed: #{success.message}."
      else
        puts "Email sent successfully to #{success.join(';')}."
      end
    end

  end

end






=begin
    # Shell runner.
    def shell(cmd)
      if dryrun?
        puts cmd
        true
      else
        puts "--> system call: #{cmd}" if trace?
        if quiet?
          silently{ system(cmd) }
        else
          system(cmd)
        end
      end
    end

    # TODO: DEPRECATE #sh in favor of #shell (?)
    alias_method :sh, :shell

    #
    def status(message)
      #puts message unless quiet?
      io.status(message)
    end

    #
    def report(message)
      #puts message unless quiet?
      io.report(message)
    end
=end


=begin
    # Provides convenient starting points in the file system.
    #
    #   root   #=> #<Pathname:/>
    #   home   #=> #<Pathname:/home/jimmy>
    #   work   #=> #<Pathname:/home/jimmy/Documents>
    #
    # TODO: Replace these with Folio when Folio's is as capable.

    # Current root path.
    def root(*args)
      Pathname['/', *args]
    end

    # Current home path.
    def home(*args)
      Pathname['~', *args].expand_path
    end

    # Current working path.
    def work(*args)
      Pathname['.', *args]
    end

    alias_method :pwd, :work

    # Bonus FileUtils features.
    #def cd(*a,&b)
    #  puts "cd #{a}" if dryrun? or trace?
    #  fileutils.chdir(*a,&b)
    #end

    # Read file.
    def file_read(path)
      File.read(path)
    end

    # Write file.
    def file_write(path, text)
      if dryrun?
        puts "write #{path}"
      else
        File.open(path, 'w'){ |f| f << text }
      end
    end

    # Assert that a path exists.
    def exists?(path)
      paths = Dir.glob(path)
      paths.not_empty?
    end
    alias_method :exist?, :exists? #; module_function :exist?
    alias_method :path?,  :exists? #; module_function :path?

    # Is a given path a regular file? If +path+ is a glob
    # then checks to see if all matches are refular files.
    def file?(path)
      paths = Dir.glob(path)
      paths.not_empty? && paths.all?{ |f| FileTest.file?(f) }
    end

    # Is a given path a directory? If +path+ is a glob
    # checks to see if all matches are directories.
    def dir?(path)
      paths = Dir.glob(path)
      paths.not_empty? && paths.all?{ |f| FileTest.directory?(f) }
    end
    alias_method :directory?, :dir? #; module_function :directory?


    # TODO: Deprecate these?

    # Assert that a path exists.
    def exists!(*paths)
      abort "path not found #{path}" unless paths.any?{|path| exists?(path)}
    end
    alias_method :exist!, :exists! #; module_function :exist!
    alias_method :path!,  :exists! #; module_function :path!

    # Assert that a given path is a file.
    def file!(*paths)
      abort "file not found #{path}" unless paths.any?{|path| file?(path)}
    end

    # Assert that a given path is a directory.
    def dir!(*paths)
      paths.each do |path|
        abort "Directory not found: '#{path}'." unless  dir?(path)
      end
    end
    alias_method :directory!, :dir! #; module_function :directory!
=end

=begin
    # Internal status report.
    # Only output if dryrun or trace mode.
    def status(message)
      io.status(message)
    end

    # Convenient method to get simple console reply.
    def ask(question, answers=nil)
      io.ask(question, answers)
    end

    # Ask for a password. (FIXME: only for unix so far)
    def password(prompt=nil)
      io.password(prompt)
    end
=end

=begin
    # Access a log by name.
    #def logfile(name)
    #  @logfile ||= {}
    #  @logfile[name.to_s] ||= (
    #    Log.new(self, project.log + name.to_s)
    #  )
    #end

    # to be deprecated
    #alias_method :log, :logfile
=end
