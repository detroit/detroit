require 'reap/hosts/host'
require 'reap/emailer'

module Reap
module Hosts

  # = Mailinglist
  #
  # Gerneic Mailing list "host". Mailinglist hosts
  # support the @announce@ task.

  class Mailinglist < Host

    register('mailinglist')

    # Email message. Options are:
    #
    #   message     Message to send.
    #   mailto      Email address to whom to mail.
    #   from        Email address from whom.
    #   subject     Subject line (default is "ANN: project version").
    #   server      Email server
    #   port        Emails server port (default is usually correct).
    #   account     Email account name (defaults to from).
    #   domain      User domain (not sure why SMTP requires this?)
    #   login       Login type (plain, login)
    #   secure      Use TLS/SSL true or false?

    def announce(options)
      options = announce_options(options)

      subject = options[:subject]
      mailto  = options[:mailto] || options[:to]
      to      = [mailto].flatten.join(", ")

      if dryrun?
        puts "email '#{subject}' to #{to}"
      else
        emailer = Emailer.new(options)
        emailer.email
      end
    end

    # Confirm announcement

    def announce_confirm?(options)
      options = announce_options(options)

      if mailto = options[:mailto] || options[:to]
        return true if force?
        to  = [mailto].flatten.join(", ")
        ans = ask("Announce to #{to}?", "yN")
        case ans.downcase
        when 'y', 'yes'
          true
        else
          false
        end
      end
    end

    #

    def announce_options(options)
      options  = options.rekey
      environ  = Emailer.environment_options
      defaults = project.defaults['email'].rekey

      result = {}
      result.update(defaults)
      result.update(environ)
      result.update(options)

      result[:subject] = (result[:subject] % [metadata.unixname, metadata.version])

      result
    end

  end

end
end

