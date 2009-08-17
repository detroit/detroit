#!/usr/bin/env ruby

# publish website to rubyforge
#
# This task publishes the source dir (deafult 'doc')
# to a rubyforge website.

main :publish do
  config = configuration['publish']

  project     = config['project']
  subdir      = config['subdir']
  source      = config['source'] || "doc"
  username    = config['username'] || ENV['RUBYFORGE_USERNAME']
  clear       = config['clear']

  if clear
    protect   = config['protect'].to_a
    exclude   = config['exclude'].to_a
  else
    protect   = %w{usage statcvs statsvn robot.txt wiki} + config['protect'].to_a
    exclude   = %w{.svn} + config['exclude'].to_a
  end

  abort "no project"  unless project
  abort "no username" unless username

  if subdir
    destination = File.join(project, subdir)
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

  rsync(*args.to_params)
end

