module Reap

  class Project

    # Generate documentation. At this time it simply
    # means generating rdocs.

    def document(options)
      rdoc(options)
      ridoc(options)
    end

    # Generate rdocs.
    #
    # Generate Rdoc documentation. Settings are the
    # same as the rdoc command's option, with two
    # exceptions: +inline+ for +inline-source+ and
    # +output+ for +op+.

    def rdoc(options=nil)
      options = configure_options(options, 'doc-rdoc', 'rdoc', 'doc')
      #options = DEFAULT['rdoc'].merge(options)

      options['title'] ||= metadata.title

      targets = options.delete('targets') || {'' => options}
      output  = options['output']
      adfile  = options['adfile']

      adfile = [adfile].flatten.find do |f|
        File.exist?(f)
      end

      targets.each do |subdir, target|
        target = options.merge(target)

        target_solo = target['solo']
        target_main = Dir.glob(target['main'].to_s, File::FNM_CASEFOLD).first

        #target_main   = File.expand_path(target_main) if target_main
        #target_output = File.expand_path(File.join(output, subdir))
        target_output = File.join(output, subdir)

        cmdopts = {}
        #cmdopts['op']            = target_output
        cmdopts['main']          = target_main if target_main
        cmdopts['template']      = target['template'] || ENV['RDOC_TEMPLATE'] || 'html'
        #cmdopts['merge']         = target['merge']
        cmdopts['inline-source'] = target['inline']
        cmdopts['exclude']       = list_option(target['exclude'])

        files = list_option(target['include'])
        files = files.collect{ |g| Dir[g] }.flatten  # Need this to remove unwanted toplevel files.
        files = files - ['Rakefile', 'Rakefile.rb']  # b/c rdoc's exlcude options doesn't work well.
        files = files - [manifest_file].compact

        #folder = target['chdir'] || '.'

        #puts "cd #{folder}" if dryrun?  # TODO: Shouldn't chdir do this automatically?
        #chdir(folder) do
          if target_solo
            input_files = files.collect{ |i| multiglob_r(i) }.flatten.reject{ |f| File.directory?(f) }
            input_files.each do |input_file|
              out = File.join(target_output, File.basename(input_file).chomp(File.extname(input_file)))
              rdoc_target(out, input_file, cmdopts)
              rdoc_insert_ads(out, adfile)
            end
          else
            input_files = files.collect{ |i| dir?(i) ? File.join(i,'**','*') : i }
            rdoc_target(target_output, input_files, cmdopts)
            rdoc_insert_ads(target_output, adfile)
          end
        #end
      end
    end

    # Remove rdocs products.

    def clobber_rdoc(options=nil)
      options = configure_options(options, 'doc-rdoc', 'rdoc')

      output = options['output']

      if File.directory?(output)
        rm_r(output)
        puts "Removed #{output}" unless dryrun?
      end
    end

    private

    #

    def rdoc_target(output, input, rdocopt={})
      if out_of_date?(output, *input) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old rdocs
        rdocopt['op'] = output
        sh "rdoc " + [input, rdocopt].to_console
      else
        puts "RDocs are current -- #{output}"
      end
    end

    # Insert an ad if available.

    def rdoc_insert_ads(site, adfile)
      return if dryrun?
      return unless adfile && File.file?(adfile)
      adtext = File.read(adfile)
      #puts
      dirs = Dir.glob(File.join(site,'*/'))
      dirs.each do |dir|
        files = Dir.glob(File.join(dir, '**/*.html'))
        files.each do |file|
          html = File.read(file)
          bodi = html.index('<body>')
          next unless bodi
          html[bodi + 7] = "\n" + adtext
          File.write(file, html) unless dryrun?
        end
      end
    end

    public

    # generate local ri docs
    #
    # Generate RI documentation. This utilizes
    # rdoc to produce the appropriate files.

    def ridoc(options=nil)
      options = configure_options(options, 'doc-ri', 'ri')
      #options = DEFAULT['ri'].merge(options)

      cmdopts = {}
      cmdopts['op']            = options['output']
      cmdopts['exclude']       = options['exclude']

      output = options['output']
      files  = options['include'] || metadata.loadpath #['lib', '[A-Z]*']

      input = files #.collect do |i|
      #  dir?(i) ? File.join(i,'**','*') : i
      #end

      if out_of_date?(output, *input) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old ridocs

        #input = input.collect{ |i| glob(i) }.flatten
        vector = [input, cmdopts]
        sh "rdoc --ri -M -a #{vector.to_console}"
      else
        puts "RI Docs are current."
      end
    end

    # Remove ri products.

    def clobber_ridoc(options=nil)
      options = configure_options(options, 'doc-ri', 'ri')

      output = options['output']

      if File.directory?(output)
        rm_r(output)
        puts "Removed #{output}" unless dryrun?
      end
    end

  end

end

