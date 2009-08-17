require 'reap/announcement'

module Reap

  class Project
 
    # Generate and email a release announcement. The announcement
    # text is read from ANNOUNCE{.txt} or another template file
    # is specified, or if no template is given, the  announcemnet
    # is automatically built from project metadata, ant the 
    # CHANGES and NOTES files.
    # 
    # Templates support metadata substitutions using $name$ syntax.
    # Also, it will subsititue the first line matching /please see notes/i
    # for the notelog. And /please see change/i for the changelog.
    # 
    # The following settings apply:
    # 
    #    template     Announcement template file (ANNOUNCE.txt).
    #    to           Email address(es) to send announcemnt.
    # 
    # If <em>mailto</em> is set then these also apply:
    # 
    #    from         Message FROM address [email].
    #    subject      Subject of email message ([ANN] title verison).
    #    server       Email server to route message.
    #    port         Email server's port.
    #    domain       Email server's domain name.
    #    account      Email account name [email].
    #    login        Login type: plain, cram_md5 or login.
    #    secure       Uses TLS security, true or false?
    # 
    # The announcement will be printed to standard out before sending
    # so it can be verified.

    def announce(options=nil)
      options = configure_options(options, 'announce')

      announcement = Announcement.new do |ann|
        ann.cutoff   = options['cutoff']
        ann.template = options['template']
        ann.metadata = metadata
      end

      if dryrun?
        puts "\n#{announcement.message}\n\n" if verbose?
      else
        puts "\n#{announcement.message}\n\n"
      end

      options['message'] = announcement.message
      options['version'] = metadata.version

      options['title']   ||= metadata.title
      options['subject'] ||= "%s, v%s release"
      options['subject'] = options['subject'] % [ options['title'], metadata.version ]

      actions = []
      select  = options['hosts']

      hosts(select).each do |host|
        if host.respond_to?(:announce)
          if host.announce_confirm?(options)
            actions << lambda{ host.announce(options) }
          end
        end
      end

      actions.each{ |a| a.call }
    end

  end

end

