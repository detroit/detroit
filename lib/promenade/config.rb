module Promenade

  # Promenade configuration. Configuration comes from a main +Routine+
  # and/or +.routine+ files.
  class Config
    #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Configuration directory name (most likely a hidden "dot" directory).
    DIRECTORY = "promenade"

    # File identifier used to find a project's Schedule(s).
    FILE_EXTENSION = "schedule"

    # Current POM::Project object.
    #attr :project

    # The list of a project's routine files.
    #
    # @return [Array<String>] routine files
    attr :schedules

    # Service configurations from Routine or *.routine files.
    # 
    # @return [Hash] service settings
    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.
    #
    # @return [Hash] default settings
    attr :defaults

    # TODO: remove project argument
    def initialize(project=nil) #, *files)
      #@project = project

      #if file = project.config.glob('promenade/config.{yml,yaml}').first
      #  conf = YAML.load(File.new(file))
      #else
      #  conf = {}
      #end

      @schedules = {}
      @services  = {}
      @defaults  = {}

      load_plugins
      load_defaults
      load_schedules
    end

    #
    def project
      Promenade.project
    end

    # Load plugins from `.promenade/plugins.rb`.
    def load_plugins
      if file = project.root.glob('{.,}#{DIRECTORY}/plugins{,.rb}').first
        require file
      else
        self.defaults = {}
      end
    end

    # Load defaults from `.promenade/defaults.yml`.
    def load_defaults
      if file = project.root.glob('{.,}#{DIRECTORY}/defaults{,.yml,.yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end
    end

    #
    def load_schedules
      schedule_filenames.each do |file|
        @schedules[file] = Schedule.load(File.new(file))
        @services.merge!(schedules[file].services)
      end
    end

    # Set defaults.
    def defaults=(hash)
      @defaults = hash.to_h
    end

    # If a `Schedule` or `.schedule` file exists, then it is returned. Otherwise
    # all `*.schedule` files are loaded. To load `*.schedule` files from another
    # directory add the directory to config options file.
    def schedule_filenames
      @schedule_filenames ||= (
        files = []
        ## match 'Routine' or '.routine' file
        files = project.root.glob("{,.}#{FILE_EXTENSION}{,.rb,.yml,.yaml}", :casefold)
        ## only files
        files = files.select{ |f| File.file?(f) }
        if files.empty?
          ## match '.promenade/*.routine' or 'promenade/*.routine'
          files += project.root.glob("{,.}#{DIRECTORY}/*.#{FILE_EXTENSION}", :casefold)
          ## match 'task/*.routine' (OLD SCHOOL)
          files += project.task.glob("*.#{FILE_EXTENSION}", :casefold)
          ## only files
          files = files.select{ |f| File.file?(f) }
        end
        files
      )
    end

=begin
    # If using a `Routine` file and want to import antoher file then use
    # `import:` entry.
    def load_promenade_file(file)
      #@dir = File.dirname(file)

      schedules[file] = 

      # TODO: can we just read the first line of the file and go from there?
      #text = File.read(file).strip

      ## if yaml vs. ruby file
      #if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
      #  #data = parse_promenade_file_yaml(text, file)
      #  YAML.load(text)
      #else
      #  data = parse_promenade_file_ruby(text, file)
      #end    

      ## extract defaults
      #if defaults = data.delete('defaults')
      #  @defaults.merge!(defaults)
      #end

      ## import other files
      #if import = data.delete('import')
      #  [import].flatten.each do |glob|
      #    routine(glob)
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

    ## Parse a YAML-based routine.
    #def parse_promenade_file_yaml(text, file)
    #  YAMLParser.parse(self, text, file)
    #end

    ## Parse a Ruby-based routine.
    #def parse_promenade_file_ruby(text, file)
    #  RubyParser.parse(self, text, file)
    #end

    ## TODO: Should the +dir+ be relative to the file or project.root?
    #def routine(glob)
    #  pattern = File.join(@dir, glob)
    #  Dir[pattern].each{ |f| load_promenade_file(f) }
    #end

  end

end
