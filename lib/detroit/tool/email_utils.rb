module Detroit

  # The Mail utility module provides an easy to use +email+ method.
  module EmailUtils

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
      #options[:file] = localize(options[:file]) if options[:file]
      emailer = Emailer.new(options.rekey)
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

      #
      def environment_options
        options = {}
        options[:server]   = ENV['EMAIL_SERVER']
        options[:from]     = ENV['EMAIL_FROM']
        options[:account]  = ENV['EMAIL_ACCOUNT'] || ENV['EMAIL_FROM']
        options[:password] = ENV['EMAIL_PASSWORD']
        options[:port]     = ENV['EMAIL_PORT']
        options[:domain]   = ENV['EMAIL_DOMAIN']
        options[:login]    = ENV['EMAIL_LOGIN']
        options[:secure]   = ENV['EMAIL_SECURE']
        options
      end

      def new_with_environment(options={})
        environment_options.merge(options.rekey)
        new(options)
      end
    end

    attr_accessor :server
    attr_accessor :port
    attr_accessor :account
    attr_accessor :passwd
    attr_accessor :login
    attr_accessor :secure
    attr_accessor :domain
    attr_accessor :from
    attr_accessor :mailto
    attr_accessor :subject
    attr_accessor :message

    #

    #
    def initialize(options={})
      require_smtp

      options = options.rekey

      if not options[:server]
        options = self.class.environment_options.merge(options)
      end

      @mailto    = options[:to] || options[:mailto]

      @from      = options[:from]
      @message   = options[:message]
      @subject   = options[:subject]
      @server    = options[:server]
      @account   = options[:account]
      @passwd    = options[:password]
      @login     = options[:login]
      @secure    = options[:secure] #.to_b
      @domain    = options[:domain]
      @port      = options[:port]

      @port    ||= secure ? 465 : 25
      @port = @port.to_i

      @account ||= @from

      @login   ||= :plain
      @login = @login.to_sym

      @passwd ||= self.class.password

      @domain ||= @server

      # save the password for later use
      self.class.password = @passwd
    end

    #

    def email(options={})
      options.rekey

      message = options[:message] || self.message
      subject = options[:subject] || self.subject
      from    = options[:from]    || self.from
      mailto  = options[:mailto]  || options[:to] || self.mailto

      raise ArgumentError, "missing email field -- server"  unless server
      raise ArgumentError, "missing email field -- account" unless account

      raise ArgumentError, "missing email field -- from"    unless from
      raise ArgumentError, "missing email field -- mailto"  unless mailto
      raise ArgumentError, "missing email field -- subject" unless subject

      passwd ||= password("#{account} password:")

      mailto = [mailto].flatten.compact

      msg = ""
      msg << "From: #{from}\n"
      msg << "To: #{mailto.join(';')}\n"
      msg << "Subject: #{subject}\n"
      msg << ""
      msg << message

      #p server, port, domain, account, passwd, login, secure if verbose?

      begin
        if Net::SMTP.respond_to?(:enable_tls) && secure
          Net::SMTP.enable_tls
          Net::SMTP.start(server, port, domain, account, passwd, login, secure) do |smtp|
            smtp.send_message(msg, from, mailto)
          end
        else
          Net::SMTP.start(server, port, domain, account, passwd, login) do |smtp|
            smtp.send_message(msg, from, mailto)
          end
        end
        return mailto
      rescue Exception => e
        return e
      end
    end

    # Ask for a password.
    #
    # FIXME: Does not hide password.

    def password(msg=nil)
      msg ||= "Enter Password: "
      inp = ''

      $stdout << msg

      inp = STDIN.gets.chomp

      #begin
      #  system "stty -echo"
      #  inp = gets.chomp
      #ensure
      #  system "stty echo"
      #end

      return inp
    end

    #
    def require_smtp
      begin
        require 'facets/net/smtp_tls'
      rescue LoadError
        require 'net/smtp'
      end
    end

  end

end



=begin
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
    def email(message, settings)
      settings ||= {}
      settings.rekey!

      server    = settings[:server]
      account   = settings[:account]  || ENV['EMAIL_ACCOUNT']
      passwd    = settings[:password] || ENV['EMAIL_PASSWORD']
      login     = settings[:login].to_sym
      subject   = settings[:subject]
      mail_to   = settings[:to]     || settings[:mail_to]
      mail_from = settings[:from]   || settings[:mail_from]
      secure    = settings[:secure]
      domain    = settings[:domain] || server

      port    ||= (secure ? 465 : 25)
      account ||= mail_from
      login   ||= :plain

      #mail_to = nil if mail_to.empty?

      raise ArgumentError, "missing email field -- server"  unless server
      raise ArgumentError, "missing email field -- account" unless account
      raise ArgumentError, "missing email field -- subject" unless subject
      raise ArgumentError, "missing email field -- to"      unless mail_to
      raise ArgumentError, "missing email field -- from"    unless mail_from

      passwd ||= password(account)

      mail_to = [mail_to].flatten.compact

      msg = ""
      msg << "From: #{mail_from}\n"
      msg << "To: #{mail_to.join(';')}\n"
      msg << "Subject: #{subject}\n"
      msg << ""
      msg << message

      begin
        Net::SMTP.enable_tls if Net::SMTP.respond_to?(:enable_tls) and secure
        Net::SMTP.start(server, port, domain, account, passwd, login) do |s|
          s.send_message( msg, mail_from, mail_to )
        end
        puts "Email sent successfully to #{mail_to.join(';')}."
        return true
      rescue => e
        if trace?
          raise e
        else
          abort "Email delivery failed."
        end
      end
    end
=end

