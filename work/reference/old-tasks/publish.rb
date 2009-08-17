module Reap

  class Project

    # Publish website to rubyforge.
    #
    # This task publishes the source dir (deafult 'doc')
    # to a rubyforge website.
    #
    # Uses RSync to upload files to webserver.
    #
    # TODO: Add FTP/SFTP support.

    def publish(options=nil)
      options = configure_options(options, 'publish', 'rubyforge')

      project  = options['project']  || metadata.project
      webdir   = options['webdir']
      source   = options['source']
      username = options['username'] || ENV['RUBYFORGE_USERNAME']
      clear    = options['clear']
      protect  = options['protect']
      exclude  = options['exclude']

      source   ||= "doc"
      username ||= ENV['RUBYFORGE_USERNAME']

      if clear
        protect   = protect().to_a
        exclude   = exclude().to_a
      else
        protect   = %w{usage statcvs statsvn robot.txt wiki} + [protect].flatten
        exclude   = %w{.svn} + [exclude].flatten
      end

      abort "No project name." unless project
      abort "No username." unless username

      if webdir and webdir != '.'
        destination = File.join(project, webdir)
      else
        destination = project
      end

      dir = source.chomp('/') + '/'
      url = "#{username}@rubyforge.org:/var/www/gforge-projects/#{destination}"

      op = ['-rLvz', '--delete-after']  # maybe -p ?

      # Using commandline filter options didn't seem
      # to work, so I opted for creating an .rsync_filter file for
      # all cases.

      unless protect.empty? && exclude.empty?
        rsync_file = File.join(source,'.rsync-filter')
        unless file?(rsync_file)
          File.open(rsync_file, 'w') do |f|
            exclude.each{|e| f << "- #{e}\n"}
            protect.each{|e| f << "P #{e}\n"}
          end
        end
        op << "--filter='dir-merge #{rsync_file}'"
      end

      args = op + [dir, url]

      sh "rsync #{args.to_params}"
    end

  end

end
