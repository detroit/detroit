raise "DEPRECATED"

module Detroit

  module Toolchain

    # Detroit configuration.
    #
    # TODO: Greatly simplify this, to support
    #
    class Config
      #instance_methods.each{ |m| private m unless /^__/ =~ m.to_s }

      # Configuration directory name (most likely a hidden "dot" directory).
      DIRECTORY = "detroit"

      # File identifier used to find a project's Assembly(s).
      FILE_EXTENSION = "assembly"

      # TODO: Should this be project instead?
      attr :root

      # The list of a project's assembly files.
      #
      # @return [Array<String>] routine files
      attr :assemblies

      # Worker configurations from Assembly or *.assembly files.
      # 
      # @return [Hash]
      attr :workers

      # Worker defaults. This is a mapping of worker names to
      # default settings. Very useful for when using the same
      # worker more than once.
      #
      # @return [Hash] default settings
      attr :defaults

      #
      def initialize(root, assembly_files=nil)
p "CONFIG!!!!!!!!!!!!!!!!!"
        @root = root

        if assembly_files && !assembly_files.empty?
          @assembly_filenames = assembly_files
        else
          @assembly_filenames = nil
        end

        @assemblies = {}
        @workers    = {}
        @defaults   = {}

        @loaded_plugins = {}

        load_plugins
        load_defaults
        load_assemblies
      end

      # Load a plugin.
      def load_plugin(name)
        @loaded_plugins[name] ||= (
          begin
            require "detroit-#{name}"
          rescue LoadError => e
            $stderr.puts "ERROR: #{e.message.capitalize}"
            $stderr.puts "       Perhaps `gem install detroit-#{name}`?"
            exit -1
          end
          name # true ?
        )
      end

      # Pre-load plugins using `.detroit/plugins.rb`.
      def load_plugins
        if file = root.glob('{.,}#{DIRECTORY}/plugins{,.rb}').first
          require file
        else
          self.defaults = {}
        end
      end

      # Load defaults from `.detroit/defaults.yml`.
      def load_defaults
        if file = root.glob('{.,}#{DIRECTORY}/defaults{,.yml,.yaml}').first
          self.defaults = YAML.load(File.new(file))
        else
          self.defaults = {}
        end
      end

      #
      def load_assemblies
        assembly_filenames.each do |file|
          load_assembly_file(file)
        end

        #if config = eval('self', TOPLEVEL_BINDING).rc_detroit
        #  @assemblies['(rc)'] = Assembly.new(&config)
        #  @workers.merge!(assemblies['(rc)'].workers)
        #end

        #if config = Detroit.rc_config
        #  assembly = Assembly.new do
        #    config.each do |c|
        #      track(c.profile, &c)
        #    end
        #  end
        #  @assemblies['(rc)'] = assembly
        #  @workers.merge!(assemblies['(rc)'].workers)
        #end
      end

      #
      def load_assembly_file(file)
p "HERE!!!!!!!!!"
        @assemblies[file] = Assembly::Script.load(File.new(file))
        @workers.merge!(assemblies[file].workers)
      end

      # Set defaults.
      def defaults=(hash)
        @defaults = hash.to_h
      end

      # If a `Assembly` or `.assembly` file exists, then it is returned. Otherwise
      # all `*.assembly` files are loaded. To load `*.assembly` files from another
      # directory add the directory to config options file.
      def assembly_filenames
        @assembly_filenames ||= (
          files = []
          ## match 'Assembly' or '.assembly' file
          files = root.glob("{,.,*.}#{FILE_EXTENSION}{,.rb,.yml,.yaml}", :casefold)
          ## only files
          files = files.select{ |f| File.file?(f) }
          ## 
          if files.empty?
            ## match '.detroit/*.assembly' or 'detroit/*.assembly'
            files += root.glob("{,.}#{DIRECTORY}/*.#{FILE_EXTENSION}", :casefold)
            ## match 'task/*.assembly' (OLD SCHOOL)
            files += root.glob("{task,tasks}/*.#{FILE_EXTENSION}", :casefold)
            ## only files
            files = files.select{ |f| File.file?(f) }
          end
          files
        )
      end

      #
      def each(&block)
        workers.each(&block)
      end

      #
      def size
        workers.size
      end

=begin
    # If using a `Routine` file and want to import antoher file then use
    # `import:` entry.
    def load_detroit_file(file)
      #@dir = File.dirname(file)

      assemblies[file] = 

      # TODO: can we just read the first line of the file and go from there?
      #text = File.read(file).strip

      ## if yaml vs. ruby file
      #if (/\A---/ =~ text || /\.(yml|yaml)$/ =~ File.extname(file))
      #  #data = parse_detroit_file_yaml(text, file)
      #  YAML.load(text)
      #else
      #  data = parse_detroit_file_ruby(text, file)
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

      #@workers.update(data)
    end
=end

      ## Parse a YAML-based routine.
      #def parse_detroit_file_yaml(text, file)
      #  YAMLParser.parse(self, text, file)
      #end

      ## Parse a Ruby-based routine.
      #def parse_detroit_file_ruby(text, file)
      #  RubyParser.parse(self, text, file)
      #end

      ## TODO: Should the +dir+ be relative to the file or root?
      #def routine(glob)
      #  pattern = File.join(@dir, glob)
      #  Dir[pattern].each{ |f| load_detroit_file(f) }
      #end

    end

  end

end
