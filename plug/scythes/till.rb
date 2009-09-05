#require 'sow/plugins/generic/generator'

module Reap

  # = Code Generator Service
  #
  class Sowgen < Service

    cycle :main, :generate

    # Only available if there is a template store.
    available do |project|
      Dir[::Sow::GenericGenerator::TEMPLATE_GLOB].first
    end

    attr_accessor :safe

    #
    def safe?; @safe; end

    #
    #def initialize_defaults #(arguments, options)
    #  #@arguments = arguments
    #  #@safe = options[:safe]
    #end

    #
    def generate(options={})
      options ||= {}

      #options[:root]   = root_directory

      options[:dryrun] = dryrun?
      options[:trace]  = trace?
      options[:quiet]  = quiet?
      options[:force]  = force?
      options[:safe]   = safe?

      generator = ::Sow::GenericGenerator.new([], options)
      generator.generate
    end

  end

end


=begin
  #= GenericGenerator
  #
  # TODO: Need to make template location more ribust.
  #
  class GenericGenerator < ::Sow::Generator

    # TODO: Need to narrow the possible template directories down.
    TEMPLATE_DIRECTORY = '{gen,form,forms,template,templates}'

    # Template pathname.
    def template_directory
      @template_directory ||= (
        if dir = (project.admin + TEMPLATE_DIRECTORY).first(File::FNM_CASEFOLD)
          dir
        else
          #Pathname.new(project.admin + 'form')  # ?
        end
      )
    end
=end

=begin
  class Template < Service

    service_action :generate => :generate

    TEMPLATE_STORE = 'temps'

    # File pattern(s) for templates to generate.
    attr_accessor :templates

    attr_accessor :store


    def initialize_defaults
      @templates = '**/*'
      @store     = File.join(project.admin, TEMPLATE_STORE)
    end

    # TODO: Glob needs exceptions for all vcs systems.

    def generate(options={})
      require 'erb'

      templates = options['templates'] || self.templates
      templates = [templates].flatten
      templates = templates.collect{ |t| t + '.erb'}

      paths = []
      chdir(store) do
        templates.each do |t|
          files = Dir.glob(t, File::FNM_CASEFOLD)
          files.delete_if{ |f| File.directory?(f) }
          paths.concat(files)
        end
      end

      #dirs  = paths.flatten.select{ |f| File.directory?(File.join(TEMPLATE_STORE, f)) }
      files = paths
      files.delete_if{ |f| /[.]svn/ =~ f }  # TODO: others to ignore

      #dirs.each do |dname|
      #  if File.exist?(dname) and !File.directory?(dname)
      #    raise "Directory to be created clashes with a prexistent file -- #{dname}"
      #  end
      #end

      files.each do |file|
        dir = File.dirname(file)
        raise if File.file?(dir)
        mkdir_p(dir) unless File.exist?(dir)
      end

      files.each do |fname|
        #next if File.exist?(fname)

        file = File.join(TEMPLATE_STORE, fname)

        if File.extname(file) == '.erb'
          env = TemplateEnv.new(metadata)
          erb = ERB.new(File.read(file))
          txt = erb.result(env.get_binding)
          write(fname.chomp('.erb'), txt)
        else
#          cp(file, fname)
        end
      end
    end

  end


  class TemplateEnv

    attr :metadata

    def initialize(metadata)
      @metadata = metadata
    end

    def get_binding
      binding
    end


    def notelog
      File.read('NOTES')
    end

    def changelog
      File.read('CHANGES')
    end

  end
=end

