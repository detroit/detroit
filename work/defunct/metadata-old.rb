#require 'facets/platform'
require 'reap/metadata/to_gemspec'

module Reap

  # Combines general project metadata with reap specific configuration options.
  #
  # NOTE: Better named Specification?
  #
  class Metadata

    FILE_METADATA = 'meta{,data}{.yaml,.yml}'
    #FILE_CONFIG   = '{.reap,config/reap,admin/config/reap}{.yaml,.yml,}'

    #
    def self.load(location)
      #file = find_file(location)
      data = {}

      glob = File.join(location, FILE_METADATA)
      file = Dir.glob(glob, File::FNM_CASEFOLD).first
      #raise "no metadata file" unless file

      data.update(YAML.load(File.new(file))) if file

      #glob = File.join(location, FILE_CONFIG)
      #file = Dir.glob(glob, File::FNM_CASEFOLD).first
      #data.update(YAML.load(File.new(file))) if file
      #raise "no metadata file" unless file

      #localize(data, location, 'store')
      #localize(data, location, 'source')

      new(data)
    end

    #
    #def self.localize(data, location, field)
    #  if data[field]
    #    data[field] = File.join(location, data[field])
    #  end
    #end

    #
    def self.attributes
      @attributes ||= []
    end

    #
    def self.attr_accessor(name)
      super(name)
      attributes << name.to_sym
    end

    #
    def self.alias_accessor(new, old)
      alias_method(new, old)
      alias_method("#{new}=", "#{old}=")
      attributes << new.to_sym
    end

    private

      #
      def initialize(root, fields={}) #:yield:
        initialize_defaults

        @extra = {}

        fields.each do |k, v|
          __send__("#{k}=", v)
        end

        #self.class.attributes.each do |k|
        #  __send__("#{k}=", fields[k.to_s]) if fields.key?(k.to_s)
        #end
        yield(self) if block_given?
      end

      #
      def initialize_defaults
        @authors    = []
        @loadpath   = ['lib']

        @require    = []
        @recommend  = []
        @suggest    = []
        @conflict   = []
        @replace    = []
        @provide    = []

        @formats    = ['gem', 'zip']
        #@platforms = ['source']
        #@compiler   = 'autotools'
        @distribute = '**/*'
        @exclude    = ['admin']

        @store      = 'pkg'
      end

    public

    # File this data came from (only set if Metadata#load was used.)
    attr_accessor :file

    # Version number.
    attr_accessor :version

    #
    attr_accessor :status

    # Date released. Defaults to Time.now.
    attr_accessor :released
    alias_method :date, :released

    #
    attr_accessor :codename

    #attr_accessor :buildno

    # Name or project/package.
    attr_accessor :name
    alias_accessor :project, :name

    # Title of project (this defaults to name capitalized).
    attr_accessor :title

    # Platform (nil for unviveral)
    attr_accessor :platform

    # A one-line brief description.
    attr_accessor :summary
    alias_accessor :brief, :summary

    # Detailed description.
    attr_accessor :description
    alias_accessor :abstract, :description

    # Homepage
    attr_accessor :homepage

    # Maintainer.
    attr_accessor :contact

    # List of authors.
    attr_accessor :authors

    # The date the project was started.
    attr_accessor :created

    # Copyright notice.
    attr_accessor :copyright

    # License.
    attr_accessor :license

    # What other packages *must* this package have in order to function.
    attr_accessor :require
    alias_accessor :requires, :require
    alias_accessor :depend, :require      # old terminology
    alias_accessor :dependency, :require  # old terminology

    # What other packages *should* be used with this package.
    attr_accessor :recommend

    # What other packages *could* be useful with this package.
    attr_accessor :suggest

    # What other packages does this package conflict.
    attr_accessor :conflict

    # What other packages does this package replace.
    attr_accessor :replace

    # What other package(s) does this package provide the same dependency fulfilment.
    # For example, a package 'bar-plus' might fulfill the same dependency criteria
    # as package 'bar', so 'bar-plus' is said to provide 'bar'.
    attr_accessor :provide

    # Load path(s) (used by Ruby's own site loading and RubyGems).
    # The default is 'lib/', which is usually correct.
    attr_accessor :loadpath

    # Will alwasy be bin/.
    #attr_accessor :executables

    # List of non-ruby extension configuration scripts.
    # These are used to compile the extensions.
    attr_accessor :extensions

    # Abirtary information, especially about what might be needed
    # to use this package. This is strictly information for the 
    # end-user to consider. Eg. "Needs a fast graphics card."
    attr_accessor :notes

    # Location of central vcs repository.
    attr_accessor :repository

=begin
    #
    # Build parameters
    #

    # If special parameters need to be designated per packages
    # this hash can be used. It is a hash entry that works 
    # like the hosts attributes.
    #attr_accessor :packages


    #
    # Host paramters
    #

    # Hash list of hosts. Each host entry should provide
    # a name and type, along with any other options required
    # information for the type of host. Eg.
    #
    #   hosts:
    #     rubyforge:
    #       type    : rubyforge.org
    #       unixname: foobar
    #
    #
    #attr_accessor :hosts

    #
    #attr_accessor :formats

    #
    #attr_accessor :binary

    #
    #attr_accessor :compiler


    #
    #attr_accessor :distribute
    #alias_method :include, :distribute

    #
    #attr_accessor :exclude

    #
    #attr_accessor :source

    #
    #attr_accessor :store
=end

    # 
    def title
      @title ||= @name.capitalize
    end

    #
    def summary
      if @abstract
        @abstract.to_s[0..79]
      else
        i = @description.index('.') || 79
        i = 79 if i > 79
        @description[0..i]
      end
    end

    def extensions
      @extensions ||= (
        Dir.glob('ext/**/extconf.rb')
      )
    end

    def executables
      @executables ||= (
        Dir.glob('bin/*').collect{ |bin| File.basename(bin) }
      )
    end

    def contact
      @contact ||= (
        authors.first
      )
    end

    # Contact's email address.
    def email
      @email ||= (
        if md = /<(.*?)>/.match(contact)
          md[1]
        else
          nil
        end
      )
    end

    #
    #def platform
    #  @platform ||= (
    #    if binary
    #      Platform.local.to_s
    #    else
    #      nil
    #    end
    #  )
    #end

    # TODO: Make the default fomat OS dependent.
    #def format
    #  @format ||= 'zip'
    #end

    #
    #def store
    #  @store ||= Dir.pwd
    #end

    #
    # Special writers
    #
    
    #
    def loadpath=(paths)
      @loadpath = list(paths)
    end

    def authors=(auths)
      @authors = list(auths)
    end

    def exclude=(x)
      @exclude = list(x)
      @exclude << 'admin' #unless app.configuration.file?
      @exclude
    end

    # Package name is generally in the form of +name-version+, or
    # +name-version-platform+ if +platform+ is specified.
    #
    # TODO: Improve buildno support.

    def package_name(buildno=nil)
      if buildno
        buildno = Time.now.strftime("%H*60+%M")
        versnum = "#{version}.#{buildno}"
      else
        versnum = version
      end

      if platform
        "#{name}-#{versnum}-#{platform}"
      else
        "#{name}-#{versnum}"
      end
    end

    alias_method :stage_name, :package_name


    def update(data)
      data.each do |k,v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    def valid?
      return false unless name
      return false unless version
      return false unless homepage
      return false unless contact
    end

    def assert_valid
      raise "no name"        unless name
      raise "no version"     unless version
      raise "no homepage"    unless homepage
      raise "no contact"     unless contact
      raise "no description" unless description
    end

    #
    def to_s
      str = ''
      attrs = self.class.attributes.collect{|s|s.to_s}.sort
      attrs.each do |a|
        str << "%12s: %s\n" % [a, send(a).inspect]
      end
      return str
    end

  private

    #
    def method_missing(s, *a, &b)
      case s.to_s
      when /=$/
        @extra[s] = a[0]
      else
        @extra.key?(s) ? @extra[s] : super
      end
    end

      #
      def list(l)
        case l
        when String
          l.split(/[:;\n]/)
        else
          [l.to_a].flatten.compact
        end
      end

  end

end

