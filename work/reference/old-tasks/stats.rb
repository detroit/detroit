module Reap

  class Project

#    DEFAULT['stats'] = {
#      'exclude' => ['ext']
#    }

    # Simple code count analysis.
    #
    # Scan source code counting files, lines of code and
    # comments and presents a report of it's findings.
    #
    #   loadpath   Path to include in analysis. The default
    #              is the project's loadpath.
    #
    #   exclude    File globs to exclude from analysis. Default
    #              is 'ext' b/c this does not yet support C analysis.
    #
    # TODO: Add C support for ext/.

    def stats(options=nil)
      options = configure_options(options, 'stats')

      loadpath = options['loadpath'] || metadata.loadpath
      exclude  = options['exclude']  || ['ext']

      loadpath = list_option(loadpath)
      exclude  = list_option(exclude)

      files = multiglob_r(*loadpath) - multiglob_r(*exclude)

      #() #.inject([]){ |memo, find| memo.concat(glob(find)); memo }
      #Dir.multiglob_with_default(DEFAULT_STATS_FILES)

      fc, l, c, r, t, s = *line_count(*files)

      fct, lt, ct, rt, tt, st = *([0]*6)
      if File.directory?('test')
        fct, lt, ct, rt, tt, st = *line_count('test/**/*')
        t = lt if lt > 0
      end

      rat = lambda do |d,n|
        if d > n and n != 0
          "%.1f" % [ d.to_f / n ]
        elsif n > d and d != 0
          "-" #"%.1f:1" % [ n.to_f / d ]
        elsif d == 0 or n == 0
          "-"
        else
          "1.0"
        end
      end

      per = lambda do |n,d|
        if d != 0
          (((n.to_f / d)*100).to_i).to_s + "%"
        else
          "-"
        end
      end

      max = l.to_s.size + 4

      puts
      #puts "FILES:"
      #puts "  source: #{fc}"
      #puts "  test  : #{fct}"
      #puts "  total : #{fc+fct}"
      #puts
      #puts "LINES:"
      #puts "  code  : %#{max}s   %4s" % [ c.to_s, per[c,l] ]
      #puts "  docs  : %#{max}s   %4s" % [ r.to_s, per[r,l] ]
      #puts "  space : %#{max}s   %4s" % [ s.to_s, per[s,l] ]
      #puts "  test  : %#{max}s   %4s" % [ t.to_s, per[t,l] ]
      #puts "  total : %#{max}s   %4s" % [ l.to_s, per[l,l] ]
      #puts
      #puts "Ratio to 1 :"
      #puts "  code to test : #{rat[c,t]} #{per[c,t]}"

      head = ["Total", "Code", "-%-", "Docs", "-%-", "Blank", "-%-", "Files"]
      prod = [l.to_s, c.to_s, per[c,l], r.to_s, per[r,l], s.to_s, per[s,l], fc]
      test = [lt.to_s, ct.to_s, per[ct,l], rt.to_s, per[rt,l], st.to_s, per[st,l], fct]
      totl = [(l+lt), (c+ct), per[c+ct,l+lt], (r+rt), per[r+rt,l+lt], (s+st), per[s+st,l+lt], (fc+fct)]

      puts "TYPE    %#{max}s %#{max}s %4s %#{max}s %4s %#{max}s %4s %#{max}s" % head
      puts "Source  %#{max}s %#{max}s %4s %#{max}s %4s %#{max}s %4s %#{max}s" % prod
      puts "Test    %#{max}s %#{max}s %4s %#{max}s %4s %#{max}s %4s %#{max}s" % test
      puts "Total   %#{max}s %#{max}s %4s %#{max}s %4s %#{max}s %4s %#{max}s" % totl
      puts
      puts "RATIO     Code    Docs    Blank   Test   Total"
      puts "Code   %7s %7s %7s %7s %7s" % [ rat[c,c], rat[c,r], rat[c,s], rat[c,t], rat[c,l] ]
      puts "Docs   %7s %7s %7s %7s %7s" % [ rat[r,c], rat[r,r], rat[r,s], rat[r,t], rat[r,l] ]
      puts "Blank  %7s %7s %7s %7s %7s" % [ rat[s,c], rat[s,r], rat[s,s], rat[s,t], rat[s,l] ]
      puts "Test   %7s %7s %7s %7s %7s" % [ rat[t,c], rat[t,r], rat[t,s], rat[t,t], rat[t,l] ]
      puts "Total  %7s %7s %7s %7s %7s" % [ rat[l,c], rat[l,r], rat[l,s], rat[l,t], rat[l,l] ]
      puts
    end

    private

    # Return line counts for files.

    def line_count(*files)
      files = files.inject([]) do |memo, find|
        memo.concat(Dir.glob(find)); memo
      end

      fc, l, c, t, r = 0, 0, 0, 0, 0
      bt, rb = false, false

      files.each do |fname|
        next unless fname =~ /.*rb/      # TODO should this be done?
        fc += 1
        File.open( fname ) do |f|
          while line = f.gets
            l += 1
            next if line =~ /^\s*$/
            case line
            when /^=begin\s+test/
              tb = true; t+=1
            when /^=begin/
              rb = true; r+=1
            when /^=end/
              t+=1 if tb
              r+=1 if rb
              rb, tb = false, false
            when /^\s*#/
              r += 1
            else
              c+=1 if !(rb or tb)
              r+=1 if rb
              t+=1 if tb
            end
          end
        end
      end
      s = l - c - r - t
      return fc, l, c, r, t, s
    end

  end

end
