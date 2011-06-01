module Pitstop

  # Pitstop configuration. Configuration comes from a main +Pitfile+
  # and/or +.pitfile+ task files.
  class Config
    #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Configuration directory name (usually a hidden "dot" directory).
    DIRECTORY = "pitstop"

    # File identifier used to find a project's Pitfile(s).
    FILE_EXTENSION = "pitfile"

    # Current POM::Project object.
    #attr :project

    #
    attr :pitfiles

    # Service configurations from Pitfile or task/*.pitfile files.
    # This is a hash of parameters.
    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.
    attr :defaults

    # TODO: remove project argument
    def initialize(project=nil) #, *files)
      #@project = project

      #if file = project.config.glob('pitstop/config.{yml,yaml}').first
      #  conf = YAML.load(File.new(file))
      #else
      #  conf = {}
      #end

      @pitfiles = {}
      @services = {}
      @defaults = {}

      load_plugins
      load_defaults
      load_pitfiles
    end

    #
    def project
      Pitstop.project
    end

    # Load plugins from `.pitstop/plugins.rb`.
    def load_plugins
      if file = project.root.glob('{.,}#{DIRECTORY}/plugins{,.rb}').first
        require file
      else
        self.defaults = {}
      end
    end

    # Load defaults from `.pitstop/defaults.yml`.
    def load_defaults
      if file = project.root.glob('{.,}#{DIRECTORY}/defaults{,.yml,.yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end
    end

    #
    def load_pitfiles
      pitfile_filenames.each do |file|
        @pitfiles[file] = Pitfile.load(File.new(file))
        @services.merge!(pitfiles[file].services)
      end
    end

    # Set defaults.
    def defaults=(hash)
      @defaults = hash.to_h
    end

    # If a `Pitfile` or `.pitfile` file exist, then it is returned. Otherwise
    # all `*.pitfile` files in `.pitstop/`, `pitstop/` and `task/`
    # directories.
    def pitfile_filenames
      @pitfile_filenames ||= (
        files = []
        ## match 'Pitfile' or '.pitfile' file
        files = project.root.glob("{,.}#{FILE_EXTENSION}{,.rb,.yml,.yaml}", :casefold)
        ## only files
        files = files.select{ |f| File.file?(f) }
        if files.empty?
          ## match '.pitstop/*.pitfile' or 'pitstop/*.pitfile'
          files += project.root.glob("{,.}#{DIRECTORY}/*.#{FILE_EXTENSION}", :casefold)
          ## match 'task/*.pitfile' (OLD SCHOOL)
          files += project.task.glob("*.#{FILE_EXTENSION}", :casefold)
          ## only files
          files = files.select{ |f| File.file?(f) }
        end
        files
      )
    end

=begin
    # If using a Pitfile and want to import antoher file then use
    # `import:` entry.
    def load_pitstop_file(file)
      #@dir = File.dirname(file)

      pitfiles[file] = 

      # TODO: can we just read the first line of the file and go from there?
      #text = File.read(file).strip

      ## if yaml vs. ruby file
      #if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
      #  #data = parse_pitstop_file_yaml(text, file)
      #  YAML.load(text)
      #else
      #  data = parse_pitstop_file_ruby(text, file)
      #end    

      ## extract defaults
      #if defaults = data.delete('defaults')
      #  @defaults.merge!(defaults)
      #end

      ## import other files
      #if import = data.delete('import')
      #  [import].flatten.each do |glob|
      #    pitfile(glob)
      #  end
      #end

      ## require plugins
      #if plugins = data.delete('plugins')
      #  [plugins].flatten.each do |file|
      #    require file
      #  end
      #end

      #@services.update(data)
    end
=end

    ## Parse a YAML-based pitfile.
    #def parse_pitstop_file_yaml(text, file)
    #  YAMLParser.parse(self, text, file)
    #end

    ## Parse a Ruby-based pitfile.
    #def parse_pitstop_file_ruby(text, file)
    #  RubyParser.parse(self, text, file)
    #end

    ## TODO: Should the +dir+ be relative to the file or project.root?
    #def pitfile(glob)
    #  pattern = File.join(@dir, glob)
    #  Dir[pattern].each{ |f| load_pitstop_file(f) }
    #end

  end

end
