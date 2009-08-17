module Reap
  class Domain

    def admin_directory
      @admin_directory ||= (
        dir = config.admin_directory || ('admin' if File.directory?('admin')) || '.'
        root_directory / dir
      )
    end

    def script_directory
      query = File.join(admin_directory, "script")
    end

    #def script_enduser_directory
    #  query = File.join(root_directory, "script")
    #end

    #
    def script_exist?(name)
      query = File.join(admin_directory, "script", name)
      Dir.glob(query, File::FNM_CASEFOLD).first
    end

    # TODO: Add argument so shellout.
    def script(name)
      if file = script_exist?(name)
  p file
        #shell file
        load(file)
      else
        load(File.join('reap', 'script', name)) # b/c of this extenal is being loaded after reap!!!!!!
      end
    end

    # scan task scripts for descriptions

    def script_descriptions(dir, executables_only=false)
      help = {}
      files = Dir.glob(File.join(dir,'**/*'))
      files.each do |fname|
        next if FileTest.directory?(fname)
        next if executables_only and !FileTest.executable?(fname)
        desc = ''
        File.open(fname) do |f|
          line = ''
          until f.eof?
            line = f.gets
            case line
            when /^(#!|\s*$)/
              next
            when /^\s*#(.*)/
              desc = $1.strip; break
            else
              desc = ''; break
            end
          end
        end
        help[File.basename(fname)] = desc
      end
      help
    end

    #
    #
    def script_show(descriptions=nil)
      desc = descriptions
      return if desc.keys.empty?
      max = desc.keys.max{ |a,b| a.size <=> b.size }.size + 6
      desc = desc.sort_by{|k,v| k}
      desc.each do |name, sum|
        puts "%-#{max}s # %s" % [name, sum]
      end
    end

    # Standard scripts.

    def about
      script "about"
    end

    def compile
      script "compile"
    end

    def test
      script "test"
    end

    def document
      script "document"
    end

    def package
      script "package"
    end

    def publish
      script "publish"
    end

    def release
      script "release"
    end

    def announce
      script "announce"
    end

  end
end

