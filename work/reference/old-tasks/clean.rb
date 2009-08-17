module Reap

  class Project

    # Clean scrap products. All directory paths and or file globs
    # listed under the clean configuration entry, can be removed via
    # this method. By default all files ending with "~" or .back
    # are removed. To specifcy an alternate provide a list of files
    # and/or glibs under +remove:+ sub-entry. You can also provide
    # an +exclude:+ sub-entry to isolate files not to be removed.
    # For example, on might do:
    #
    #   clean:
    #     remove [ '**/*~', '**/*.bak', '.config' ]
    #
    # Clean is run as a prerequiste to #release via #prepare.

    def clean(options=nil)
      options = configure_options(options, 'clean')

      remove  = options['remove']
      exclude = options['exclude']

      remove  = list_option(remove)
      exclude = list_option(exclude)

      files   = multiglob_r(*remove) - multiglob_r(exclude)

      make_clean if compiles?

      return if files.empty?

      puts files.join("\n")

      if verbose?
        ans = ask("Remove files?", "yN").downcase
        return unless ans == 'y' or ans == 'yes'
      end

      files.each do |f|
        rm(f) if File.exist?(f)
      end
    end

    # Run all clobber methods. This method literally looks for all other
    # methods starting with the phrase "clobber_" and calls them, then
    # runs #clean as well.

    def clobber(options=nil)
      clean
      clobber_methods = methods.select{ |m| m.to_s =~ /^clobber_/ }
      clobber_methods.each do |m|
        send(m)
      end
    end

  end

end

