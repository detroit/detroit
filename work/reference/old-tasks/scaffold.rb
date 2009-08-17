require 'erb'

module Reap

  class Project

    def scaffold(options)
      requests = options['arguments']

      if requests
        requests.each do |f|
          case f
          #when /^(meta\/)?project(info)?(.yaml|.yml)?$/i
          #  scaffold_projectfile(f)
          when /^rake(file)?$/i
            scaffold_rakefile(f)
          when /^setup[.]rb$/
            scaffold_setup_rb(f)
          when /^(task|script)s?\//i
            scaffold_task(f)
          when /^(task|script)(s)?$/
            scaffold_tasks(f)
          else
            raise "Unknown scaffolding."
          end
        end
      else
        scaffold_skeleton(options=nil)
      end
    end

    # Add project file template to project.
    #
    # FIXME: This doesn't yet work b/c reap doesn't work unless
    # a project file is already in place.

    #def scaffold_projectfile(fname)
    #  from = File.join(data_dir, 'metaset', 'meta', 'project.yaml')
    #  cp(from, fname) unless File.exist?(fname)
    #end

    # Add tasks in Rakefile form to project.

    def scaffold_rakefile(fname)
      from = File.join(data_dir, 'buildset', 'rake', 'Rakefile')
      cp(from, fname) unless File.exist?(fname)
    end

    #

    def scaffold_setup_rb(fname)
      from = File.join(data_dir, 'buidset', 'rake', 'setup.rb')
      cp(from, fname) unless File.exist?(fname)
    end

    # Add a user tasks to the project.

    def scaffold_task(fname)
      from = File.join(data_dir, 'buildset', 'tasks', 'task', File.basename(fname))
      cp(from, fname) unless File.exist?(fname)
    end

    # Add all user tasks to the project.

    def scaffold_tasks(fname)
      dir = File.join(data_dir, 'buildset', 'tasks', 'task')
      cp_r(dir, fname)
    end

    # Create a project skeleton.
    #
    # TODO: Improve scaffolding. Make more intelligent.

    def scaffold_skeleton(options=nil)
      options = (options || {}).rekey(:to_s)

      files = glob('**/*') - glob('meta/**/*') - ['.reap', 'meta']

      unless files.empty?
        ans = ask("Directory isn't empty. Are you sure you want to add scaffolding?", 'yN')
        case ans.downcase
        when 'y', 'yes'
        else
          abort "Scaffolding aborted."
        end
      end

      #      if options['svn']
      #        if glob('**/*').empty?
      #          mkdir_p('trunk')
      #          mkdir_p('branches')
      #          mkdir_p('tags')
      #          chdir('trunk')
      #        else
      #          abort "Can't create a svn repo unless directory is empty."
      #        end
      #      end

      paths = nil
      dir   = File.join(data_dir, 'base')
      chdir(dir){ paths = Dir['**/*'] }

      dirs  = paths.select{ |f| File.directory?(File.join(dir, f)) }
      files = (paths - dirs).reject{ |f| /[.]svn/ =~ f }

      dirs.each do |dname|
        if File.exist?(dname) and !File.directory?(dname)
          abort "Directory to be created clashes with a prexistent file -- #{dname}"
        end
      end

      dirs.each do |dname|
        mkdir_p(dname) unless File.exist?(dname)
      end

      files.each do |fname|
        next if File.exist?(fname)
        file = File.join(dir, fname)
        if File.extname(file) == '.erb'
          erb = ERB.new(File.read(file))
          txt = erb.result(metadata.get_binding)
          File.open(fname.chomp('.erb'), 'w'){ |f| f << txt }
        else
          cp(file, fname)
        end
      end

      # A little extra love.

      dir = File.join('lib',metadata.name)
      mkdir_p(dir) unless File.exist?(dir)
    end
 
    private

    # FIXME: RubyGems has a new way to do this. Use that instead and fix Rolls to use it too.

    def data_dir
      @datadir ||= (
        if defined?(::Library) and Library['reap']
          dd = Library['reap'].datadir
        else
          dd = File.join(Config::CONFIG['datadir'], 'reap')
        end
        File.join(dd, 'reap')
      )
    end

  end

end

