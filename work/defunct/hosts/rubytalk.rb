require 'reap/hosts/mailinglist'
require 'reap/emailer'

module Reap
module Hosts

  # = Rubytalk
  #
  # This is a Maklinglist host. It simply statically sets
  # the ruby-talk@ruby-lang.org email address and passes
  # on to it's superclass.

  class RubyTalk < Mailinglist

    register('ruby-talk', 'ruby-talk@ruby-lang.org')

    EMAIL_ADDRESS = 'ruby-talk@ruby-lang.org'

    # This sets the mailto address and passes on to the
    # super class.
    #
    # See Mailinglist#announce.

    def announce(options)
      options = options.rekey(&:to_s)
      options['mailto'] = EMAIL_ADDRESS
      super(options)
    end

    def announce_confirm?(options={})
      options = options.rekey(&:to_s)
      options['mailto'] = EMAIL_ADDRESS
      super(options)
    end
  end

end
end

