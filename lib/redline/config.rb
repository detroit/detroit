#require 'facets/boolean'

require 'redline/config/ruby_parser'
require 'redline/config/yaml_parser'

module Redline

  # Redline configuration. Configuration comes from a main +Redfile+
  # and/or +.redfile+ task files.
  class Config
    #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

    # Configuration directory name (usually a hidden "dot" directory).
    DIRECTORY = "redline"

    # File identifier used to find a project's Redfile(s).
    FILE_EXTENSION = "redfile"

    # Current POM::Project object.
    attr :project

    # Service configurations from Redfile or task/*.redfile files.
    # This is a hash of parameters.
    attr :services

    # Service defaults. This is a mapping of service names to
    # default settings. Very useful for when using the same
    # service more than once.
    attr :defaults

    #
    def initialize(project) #, *files)
      @project = project

      #if file = project.config.glob('redline/config.{yml,yaml}').first
      #  conf = YAML.load(File.new(file))
      #else
      #  conf = {}
      #end

      load_defaults

      @services = {}
      @defaults = {}

      redline_files.each do |file|
        load_redline_file(file)
      end
    end

    # Load defaults from `.redline/defaults.yml`.
    def load_defaults
      if file = project.root.glob('{.,}#{DIRECTORY}/defaults{.yml,.yaml}').first
        self.defaults = YAML.load(File.new(file))
      else
        self.defaults = {}
      end
    end

    # Set defaults.
    def defaults=(hash)
      @defaults = hash.to_h #OpenStruct.new(hash) # need two layer OpenStruct.. OpenCascade?
    end

    # If a `Redfile` or `.redfile` file exist, then it is returned. Otherwise
    # all `*.redfile` files in `.redline/`, `redline/` and `task/`
    # directories.
    def redline_files
      @redline_files ||= (
        files = []
        ## match 'Redfile' or '.redfile' file
        files = project.root.glob("{,.}#{FILE_EXTENSION}", :casefold)
        ## only files
        files = files.select{ |f| File.file?(f) }
        if files.empty?
          ## match '.redline/*.redfile' or 'redline/*.redfile'
          files += project.root.glob("{,.}#{DIRECTORY}/*.#{FILE_EXTENSION}", :casefold)
          ## match 'task/*.redfile' (OLD SCHOOL)
          files += project.task.glob("*.#{FILE_EXTENSION}", :casefold)
          ## only files
          files = files.select{ |f| File.file?(f) }
        end
        files
      )
    end

    # If using a Redfile and want to import antoher file then use
    # `import:` entry.
    def load_redline_file(file)
      dir  = File.dirname(file)
      text = File.read(file).strip

      ## if yaml vs. ruby file
      if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
        data = parse_redline_file_yaml(text, file)
      else
        data = parse_redline_file_ruby(text, file)
      end    

      ## extract defaults
      #if defaults = data.delete('defaults')
      #  @defaults.merge!(defaults)
      #end

      ## import other files
      if import = data.delete('import')
        [import].flatten.each do |glob|
          pattern = File.join(dir,glob)
          Dir[pattern].each{ |f| load_redline_file(f) }
        end
      end

      ## require plugins
      if plugins = data.delete('plugins')
        [plugins].flatten.each do |file|
          require file
        end
      end

      @services.update(data)
    end

    # Parse a YAML-based redfile.
    def parse_redline_file_yaml(text, file)
      YAMLParser.parse(self, text, file)
    end

    # Parse a Ruby-based redfile.
    def parse_redline_file_ruby(text, file)
      RubyParser.parse(self, text, file)
    end

  end

end
