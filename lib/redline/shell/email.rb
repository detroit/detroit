module Redline

  class Shell

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
      options.rekey!
      options.delete_if{ |k,v| v.nil? }
      options[:file] = localize(options[:file]) if options[:file]
      if options[:env]
        emailer = Emailer.new_with_environment(options)
      else
        emailer = Emailer.new(options)
      end
      success = emailer.email
      if Exception === success
        puts "Email failed: #{success.message}."
      else
        puts "Email sent successfully to #{success.join(';')}."
      end
    end

  end

  # Emailer class makes it easy send out an email.
  #
  # Settings:
  #
  #     subject      Subject of email message.
  #     from         Message FROM address [email].
  #     to           Email address to send announcemnt.
  #     server       Email server to route message.
  #     port         Email server's port.
  #     port_secure  Email server's port.
  #     domain       Email server's domain name.
  #     account      Email account name if needed.
  #     password     Password for login..
  #     login        Login type: plain, cram_md5 or login [plain].
  #     secure       Uses TLS security, true or false? [false]
  #     message      Mesage to send -or-
  #     file         File that contains message.
  #
  class Emailer

    class << self
      # Used for caching password between usages.
      attr_accessor :password

      def new_with_environment(options={})
        new(environment_options(options))
      end

      # Extract options from environment settings.
      def environment_options(options={})
        options.rekey!
        options[:server]   ||= ENV['EMAIL_SERVER']
        options[:from]     ||= ENV['EMAIL_FROM']
        options[:account]  ||= ENV['EMAIL_ACCOUNT'] || ENV['EMAIL_FROM']
        options[:password] ||= ENV['EMAIL_PASSWORD']
        options[:port]     ||= ENV['EMAIL_PORT']
        options[:domain]   ||= ENV['EMAIL_DOMAIN']
        options[:login]    ||= ENV['EMAIL_LOGIN']
        options[:secure]   ||= ENV['EMAIL_SECURE']
        options.delete_if{ |k,v| v.nil? }
        options
      end
    end

    attr_accessor :server
    attr_accessor :port
    attr_accessor :account
    attr_accessor :password
    attr_accessor :login
    attr_accessor :secure
    attr_accessor :domain
    attr_accessor :from
    attr_accessor :mailto
    attr_accessor :subject
    attr_accessor :message

    # New Emailer.
    def initialize(options={})
      options = options.rekey

      if options.empty?
        options = self.class.environment_options.merge(options)
      end

      @mailto    = options[:to] || options[:mailto]

      @from      = options[:from]
      @message   = options[:message]
      @subject   = options[:subject]
      @server    = options[:server]
      @account   = options[:account]
      @password  = options[:password]
      @login     = options[:login]
      @secure    = options[:secure] #.to_b
      @domain    = options[:domain]
      @port      = options[:port]

      @port    ||= secure ? 465 : 25
      @port = @port.to_i

      @account ||= @from

      @login   ||= :plain
      @login = @login.to_sym

      @password ||= self.class.password

      @domain   ||= @server

      # save the password for later use
      self.class.password = @password
    end

    # Deliver email message.
    def email(options={})
      options = options.rekey

      body    = options[:message] || self.message
      subject = options[:subject] || self.subject
      from    = options[:from]    || self.from
      mailto  = options[:mailto]  || options[:to] || self.mailto

      raise ArgumentError, "missing email field -- server"  unless server
      raise ArgumentError, "missing email field -- account" unless account

      raise ArgumentError, "missing email field -- from"    unless from
      raise ArgumentError, "missing email field -- mailto"  unless mailto
      raise ArgumentError, "missing email field -- subject" unless subject

      secret = password || ask_password("#{account} password: ")

      mailto = [mailto].flatten.compact

      #p server, port, domain, account, secret, login, secure #if $DEBUG

      begin
        deliver_via_smtp(body, from, mailto, subject, secret)
      rescue Exception => error
        return error
      end

      return mailto
    end

    #
    def deliver_via_smtp(body, from, mailto, subject, secret)
      require_smtp

      msg = ""
      msg << "From: #{from}\n"
      msg << "To: #{mailto.join(';')}\n"
      msg << "Subject: #{subject}\n"
      msg << ""
      msg << body

      smtp = Net::SMTP.new(server, port) #, domain, account, secret, login)
      smtp.enable_starttls if secure
      smtp.start(domain, account, secret, login) do |s|
        s.send_message(msg, from, mailto)
      end
    end

    # Ask for a password.
    def ask_password(msg=nil)
      msg ||= "Enter Password: "
      inp = ''
      $stdout << msg
      inp = STDIN.gets.chomp
      return inp
    end

    #
    def require_smtp
      require 'openssl'
      require 'net/smtp'
      if RUBY_VERSION < '1.8.7'
        begin
          require 'smtp_tls'
        rescue LoadError
        end
      end
    end

  end

end

