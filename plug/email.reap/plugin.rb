require 'reap/plugin'
require 'facets/boolean'

module Reap
module Plugins

  # = Email Plugin
  #
  # The Email plugin supports the @promote@ action
  # to send out an annoucement to a set of email addresses.
  #
  # By default it generates an release announcement based
  # on your README.* file.
  #
  class EMail < Plugin

    pipeline :main, :promote do
      announce
    end

    pipeline :attn, :promote do
      announce
    end

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
    attr_accessor :secure

    # Set if email service is using TLS/SSL security.
    def secure=(s)
      @secure = s.to_b
    end

    # Message to send. Defaults to a generated release announcement.
    def message
      @message ||= project.announcement(file)
    end

    # Email announcement message.
    def announce
      mailopts = self.mailopts

      if mailto.empty?

      else
        if dryrun?
          subject = mailopts['subject']
          mailto  = mailopts['to'].flatten.join(", ")
          puts "email '#{subject}' to #{mailto}"
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
        ans = ask("Announce to #{to}?", "(v)iew|(y)es|(N)o")
        case ans.downcase
        when 'y', 'yes'
          true
        when 'v', 'view'
          puts message
          mail_confirm?
        else
          false
        end
      end
    end

    #
    def mailopts
      { 'message' => self.message,
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
    end

  private

    def initialize_defaults
      @mailto   = ['rubytalk@ruby-lang.org']
      @subject  = "%s v%s released" % [metadata.title, metadata.version]
      @file     = 'doc/ANN{,OUNCE}{,.txt,.rdoc}'

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
end

