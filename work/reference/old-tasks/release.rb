require 'reap/hosts/rubyforge'

module Reap

  class Project

    # Release packages (to rubyforge). This generates
    # the packages, and then distributes them to the
    # file server.

    def release(options={})
      package(options)


      release_options = configure_options(options, 'release')

      store   = 'pkg'
      version = metadata.version

      release_options['version'] = version
      release_options['store']   = store

      changelog = release_options['changelog'] #|| DEFAULT['release']['changelog'] || DEFAULT['rubyforge']['changelog']
      notelog   = release_options['notelog']   #|| DEFAULT['release']['notelog']   || DEFAULT['rubyforge']['notelog']

      changelog = Dir.glob(changelog.to_s, File::FNM_CASEFOLD).first
      notelog   = Dir.glob(notelog.to_s, File::FNM_CASEFOLD).first

      release_options['changelog'] = changelog if changelog && File.exist?(changelog)
      release_options['notelog']   = notelog   if notelog && File.exist?(notelog)

      files   = release_options['files'] || []

      if files.empty?
        files = Dir[File.join(store, '*')].select do |file|
          /#{version}[.]/ =~ file
        end
        release_options['files'] = files
        #files = Dir.glob(File.join(store,"#{name}-#{version}*"))
      end


      actions = []
      select  = options['hosts']

      hosts(select).each do |host|
        if host.respond_to?(:release)
          # Not going to do dryrun in Rubyforge class b/c it still requires logging in.
          if dryrun?
            puts "release: #{} #{host.class.basename.downcase}"
          else
            if host.release_confirm?(release_options)
              actions << lambda{ host.release(release_options) }
            end
          end
        end
      end

      actions.each{ |a| a.call }
    end

    # A complete rollout. This will prepare (clean, stamp and package),
    # then document, publish and release, tag and announce. It will
    # do under direction. You can use the --force option to bypass this
    # and have evey action taken automatically.

    def rollout(options={})
      if force?
        doc, pub, ann, tag = true, true, true, true
      else
        doc = ask("Generate doumentation?", "yN").downcase =~ /^(y|yes)$/i
        pub = ask("Publish website?      ", "yN") =~ /^(y|yes)$/i
        tag = scm? ? (ask("Tag current version?  ", "yN") =~ /^(y|yes)$/i) : false      
        ann = ask("Announce release?     ", "yN") =~ /^(y|yes)$/i
        puts
      end

      document(options) if doc
      publish(options)  if pub

      #package(options)
      release(options)
      scm_tag(options)  if tag
      announce(options) if ann
    end

  end

end

