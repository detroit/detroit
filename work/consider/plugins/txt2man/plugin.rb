require 'reap/plugin'

module Reap
module Plugins

  # = Txt2Man Plugin
  #
  class Txt2Man < Plugin

    pipeline :main, :document

    available do |project|
      (project.root + 'man').directory?
    end

    #
    def initialize_defaults
    end

    def document
      mkdir_p(project.cache + "reap/man")

      pages = (project.root + 'man').glob('*')
      pages.each do |page|
        fname = File.basename(page.to_s)
        title = fname.chomp(page.extname)
        rem = ''
        txt = ''
        page.each_line do |line|
          next  if line.strip.empty?
          break if line[0,3] != '.\"'
          rem << line
          txt << line[4..-1]
        end
        # rewirte manpage file with remark header (clears out any old generation)
        page.open('w'){ |f| f << rem }
        # create temporary manpage file stripped of comment markers.
        tmp = project.cache + "reap/man/#{fname}"
        File.open(tmp, 'w'){ |f| f << txt }
        if dryrun? #pretend?
          puts "txt2man -t #{title} #{tmp} >> #{page}"
        else
          # append results of txt2man to mapage.
          `txt2man -t #{title} #{tmp} >> #{page}`
          puts "Updated man/#{fname}"
        end
      end
    end

  end # class Manpage

end
end # module Reap

