module Reap

  class Project

    # Update VERSION stamp file.
    #
    # This file is either called VERSION, or meta/version
    # (case-insensitive and with optional .txt extension).
    #
    # The format of the files is:
    #
    #   x.y.z status (date)
    #
    # For exmaple:
    #
    #   1.2.4 alpha (2008-10-10)
    #
    # On the command line:
    #
    #    --major    will bump the major number
    #    --minor    will bump the minor number
    #    --tiny     will bump the tiny  number
    #    --teeny    will bump the teeny number
    #
    # One can alternately specify the entire version:
    #
    #   --version=x.y.z
    #
    # As well as status:
    #
    #   --status=(alpha, beta, rc1, rc2, ...)
    #
    # TODO: Should we also update a lib/version.rb file?
    # TODO: Considerding createing a standard status marker (a=alpha, b=beta, r=release candidate)
    #       So a version would read, eg. 1.2.4a, or with status number, eg. 1.2.4r1).

    def stamp(options={})
      old_version = metadata.version.dup
      old_status  = metadata.status.dup
      old_date    = metadata.date.dup

      version = options['version']
      status  = options['status']

      bumps = [ options['major'], options['minor'], options['tiny'], options['teeny'] ]

      bump  = bumps.any?{|x|x}

      abort "Specify bumps or version, not both." if bump and version

      #options = configure_options(options, 'stamp')

      version = version || metadata.version || '0.0.0'
      status  = status  || metadata.status  || '0.0.0'

      if bump
        points = version.to_s.split(/[.]/).collect do |x|
          x.to_i
        end

        if options['major']
          points[0] ||= 0
          points[0] += 1
          points[1..-1] = *([0] * points[1..-1].size)
        elsif options['minor']
          points[1] ||= 0
          points[1] += 1
          points[2..-1] = *([0] * points[2..-1].size)
        elsif options['tiny']
          points[2] ||= 0
          points[2] += 1
          points[3..-1] = *([0] * points[3..-1].size)
        elsif options['teeny']
          points[3] ||= 0
          points[3] += 1
        end

        version = points.join('.') #.chomp('.0')
      else
        abort "Invalid version -- #{version}" unless String===version && /^[0-9]/ =~ version
      end

      date = Time.now.strftime('%Y-%m-%d')

      #meta = File.directory?('meta')

      file = libspec_file

      #file = glob('{,meta/}version{,.txt}', File::FNM_CASEFOLD).first
      #file = (meta ? 'meta/version' : 'VERSION') unless file

      #text = "#{version} #{status} (#{rdate})"

      #exists = File.exist?(file)

      #if exists
      #  old_text = File.read(file).strip
      #  old_version, old_status, old_date = *old_text.split(/\s/)

        if old_version == "#{version}" && old_status == status
          puts "#{version} #{status} (#{date})"
          return
        end
      #end

      if dryrun?
        puts "version: "#{version} #{status} (#{date})""
      else
        #if exists
        #  write(file, text)
        #  puts text
        #  puts "#{file} updated."
        #else
          text = File.read(file)
          yaml_append(text, /version(\s*):\s*.*?$/mi , 'version\1: ' + "'#{version}'")
          yaml_append(text, /status(\s*):\s*.*?$/mi  , 'status\1: ' + "'#{status}'")
          yaml_append(text, /date(\s*):\s*.*?$/mi    , 'date\1: ' + "'#{date}'")
          write(file, text)
        #end

        metadata.version  = version
        metadata.status   = status
        metadata.released = Time.now

        puts "#{version} #{status} (#{date})"
      end

      # TODO: Stamp .roll if roll file exists.
      # should we read current .roll file and use as defaults?
      if File.exist?('.roll')
        str = []
        str << "name    = #{metadata.name}"
        str << "version = #{metadata.version}"
        str << "status  = #{metadata.status}"
        str << "date    = #{metadata.date}"
        str << "default = #{metadata.default}"
        str << "libpath = #{metadata.libpath}"
        # File.open('.roll','w'){ |f| f << str.join("\n") }
      end
    end

    #

    def yaml_append(text, re, sub)
      if re =~ text
        text.sub!(re, sub)
      else
        text << "\n" << sub
      end
    end

  end

end

