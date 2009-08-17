require 'reap/systems'

module Reap

  class Project

    # Determine if project is under version control.
    #
    # TODO: scm? may need to be made more robsut.

    def scm?
      Systems::System.detect
    end

    # Generate ChangeLog. This method routes to the 
    # appropriate method for the project's source
    # control manager.
    #
    #   change     File path to store rdoc formated changelog. Default is 'log/changelog.txt'.
    #   xmlchange  File path to store XML formated changelog. Default is 'doc/log/changelog.xml'.
    #
    # Set either to false to supress creation.

    def scm_log(options={})
      #create_txtlog = (options['txtlog'] != false)
      #create_xmllog = (options['xmllog'] != false)

      xmlout = options['xmloutput'] || 'site/log'  # TODO: How to set site/?

      #if create_txtlog
        txtlog = apply_naming_policy('changelog', 'rdoc')
        txtlog = File.join('log', txtlog)
      #end

      #if create_xmllog
        xmllog = apply_naming_policy('changelog', 'xml')
        xmllog = File.join(xmlout, xmllog)
      #end

      #txtlog = File.join('lib', txtlog) unless txtlog.include?('/')
      #xmllog = File.join(xmldir, xmllog) unless xmllog.include?('/')

      txtlog ||= options['txtlog']
      xmllog ||= options['xmllog']

      scm.log(txtlog)
      scm.log_xml(xmllog) if xmllog
    end

    # Tag current versoin of project. This method routes
    # to the appropriate method for the project's source
    # control manager.
    #
    #   message       Optional commit message. This is intended for commandline
    #                 usage. (Use -m for shorthand).
    #
    # TODO: How should metadata.repository come into play here?

    def scm_tag(options=nil)
      options = configure_options(options, 'scm-tag', 'scm')
      scm.tag(options)
    end

    # Branch current version of project. This method routes
    # to the appropriate method for the project's source
    # control manager.
    #
    #   message    Optional commit message. This is intended
    #              for commandline usage. (Use -m for shorthand).
    #
    # TODO: How should metadata.repository come into play here?

    def scm_branch(options=nil)
      options = configure_options(options, 'scm-branch', 'scm')
      scm.branch(options)
    end

  end

end

