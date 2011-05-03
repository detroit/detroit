require 'facets/boolean'

module Redline::Plugins

  # = Email Plugin
  #
  # The Email plugin supports the @promote@ action
  # to send out an annoucement to a set of email addresses.
  #
  # By default it generates a release announcement based
  # on your README.* file.
  #
  class EMail < Service

    cycle :main, :announce

    cycle :attn, :announce

    #available do |project|
    #  true # when ?
    #end

    # Message file to send.
    attr_accessor :file

    # List of email addresses to whom to email.
    attr_accessor :mailto

    alias_method :to,  :mailto
    alias_method :to=, :mailto=

    # Email address from whom.
    attr_accessor :from

    # Subject line (default is "ANN: title version").
    attr_accessor :subject

    # Email server.
    attr_accessor :server

    # Emails server port (default is usually correct).
    attr_accessor :port

    # Email account name (defaults to from).
    attr_accessor :account

    # User domain (not sure why SMTP requires this?).
    attr_accessor :domain

    # Login type (plain, login).
    attr_accessor :login

    # Use TLS/SSL true or false?
    attr_reader :secure

    # Components of announcment.
    attr_accessor :parts

    # Do not use environment variables for email defaults.
    attr_accessor :noenv

    # Set if email service is using TLS/SSL security.
    def secure=(s)
      @secure = s.to_b
    end

    # Message to send. Defaults to a generated release announcement.
    def message
      @message ||= (
        path = Dir[file].first if file
        if path
          project.announcement(File.new(file))
        else
          parts.map{ |part| /^file:\/\// =~ part.to_s ? $' : part }
          project.announcement(*parts)
        end
      )
    end

    # Email announcement message.
    def announce
      apply_environment

      mailopts = self.mailopts

      if mailto.empty?
        report "No recipents given."
      else
        if trial?
          subject = mailopts['subject']
          mailto  = mailopts['to'].flatten.join(", ")
          report "email '#{subject}' to #{mailto}"
        else
          #emailer = Emailer.new(mailopts)
          #emailer.email
          if mail_confirm?
            email(mailopts)
          end
        end
      end
    end

    # Confirm announcement
    def mail_confirm?
      if mailto
        return true if force?
        to  = [mailto].flatten.join(", ")
        ans = ask("Announce to #{to} [(v)iew (y)es (N)o]? ")
        case ans.downcase
        when 'y', 'yes'
          true
        when 'v', 'view'
          puts "From: #{from}"
          puts "To: #{to}"
          puts "Subject: #{subject}"
          puts
          puts message
          mail_confirm?
        else
          false
        end
      end
    end

    #
    def mailopts
      options = {
        'message' => self.message,
        'to'      => self.to,
        'from'    => self.from,
        'subject' => self.subject,
        'server'  => self.server,
        'port'    => self.port,
        'account' => self.account,
        'domain'  => self.domain,
        'login'   => self.login,
        'secure'  => self.secure
      }
      options.delete_if{|k,v| v.nil?}
      options
    end

    # Apply environment settings.
    def apply_environment
      return if noenv
      @server   ||= ENV['EMAIL_SERVER']
      @from     ||= ENV['EMAIL_FROM']
      @account  ||= ENV['EMAIL_ACCOUNT'] || ENV['EMAIL_FROM']
      @password ||= ENV['EMAIL_PASSWORD']
      @port     ||= ENV['EMAIL_PORT']
      @domain   ||= ENV['EMAIL_DOMAIN']
      @login    ||= ENV['EMAIL_LOGIN']
      @secure   ||= ENV['EMAIL_SECURE']
    end

  private

    def initialize_defaults
      @mailto   = ['rubytalk@ruby-lang.org']
      @subject  = "[ANN] %s v%s released" % [metadata.title, metadata.version]
      @file     = nil #'doc/ANN{,OUNCE}{,.txt,.rdoc}' TODO: default announcment file?
      @parts    = [:message, :description, :resources, :notes, :changes]

      #mailopts = Ratch::Emailer.environment_options.rekey(&:to_s)  # FIXME
      #@port    = mailopts['port']
      #@server  = mailopts['server']
      #@account = mailopts['account']  #|| metadata.email
      #@domain  = mailopts['domain']   #|| metadata.domain
      #@login   = mailopts['login']
      #@secure  = mailopts['secure']
      #@from    = mailopts['from']     #|| metadata.email
    end

    #
    #def announce_options(options)
    #  options  = options.rekey
    #  environ  = Emailer.environment_options
    #  defaults = project.defaults['email'].rekey
    #
    #  result = {}
    #  result.update(defaults)
    #  result.update(environ)
    #  result.update(options)
    #
    #  result[:subject] = (result[:subject] % [metadata.unixname, metadata.version])
    #
    #  result
    #end

  end

end


