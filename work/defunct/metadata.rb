require 'time'
require 'facets/module/alias_accessor'
#require 'reap/project/metadata/version'

module Reap

  class Project

    # = Poject Metadata
    #
    class Metadata

      METAFILE = 'meta{,data}{.yaml,.yml}'

      ### Project root directory.
      attr :rootfolder

      ### Metadata directory.
      attr :metafolder

      ### YAML based metadata file.
      attr :metafile

      ### Version stamp.
      #attr :version_stamp

      ### New Metadata object.
      def initialize(rootfolder)
        initialize_defaults

        @rootfolder = rootfolder
        @metafile   = rootfolder.glob_first(METAFILE, :casefold)

        if @metafile
          data = YAML.load(File.new(file))
          data.each do |k,v|
            send("#{k}=", v)
          end
        end

        # TODO: apply some code golf
        if (rootfolder + '.meta').directory?
          @metafolder = rootfolder + '.meta'
        elsif (rootfolder + 'meta').directory?
          @metafolder = rootfolder + 'meta'
        end

        if @metafolder
          @metafolder.glob('*').each do |f|
            send("#{f.basename}=", f.read.strip) if respond_to?("#{f.basename}=")
          end
        end

        #@version_stamp = Version.new(rootfolder)
      end

      #
      def initialize_defaults
        @loadpath   = ['lib']
        @authors    = []
        @require    = []
        @recommend  = []
        @suggest    = []
        @conflict   = []
        @replace    = []
        @provide    = []
        #@platforms = ['source']
        #@compiler   = 'autotools'
        #@distribute = '**/*'
        #@exclude    = ['admin']
        #@store      = 'pkg'
      end

=begin
      ######################
      # Version Attributes #
      ######################

      ### Unixname of this application/library.
      def project  ; version_stamp.project  ; end

      ### Alias for #project.
      def name     ; version_stamp.project  ; end

      ### Version number.
      def version  ; version_stamp.version  ; end

      ### Current status (stable, beta, alpha, rc1, etc.)
      def status   ; version_stamp.status   ; end

      ### Date this version was released.
      def release  ; version_stamp.release  ; end

      ### Code name of the release (eg. Woody)
      def codename ; version_stamp.codename ; end
=end

      ######################
      # General Attributes #
      ######################

      # Unixname of this application/library.
      attr_accessor :package

      # Unixname of the project to which this package belongs (defaults to package).
      attr_accessor :project

      # Version number of package.
      attr_accessor :version

      # Current status (stable, beta, alpha, rc1, etc.)
      attr_accessor :status

      # Date this version was released.
      attr_accessor :release

      # Code name of the release (eg. Woody)
      attr_accessor :codename


      # Title of package (this defaults to name capitalized).
      attr_accessor :title

      # Platform (nil for unviveral)
      attr_accessor :platform

      # A one-line brief description.
      attr_accessor :summary

      # Detailed description.
      attr_accessor :description

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
      attr_accessor :requires

      # What other packages *should* be used with this package.
      attr_accessor :recommends

      # What other packages *could* be useful with this package.
      attr_accessor :suggests

      # What other packages does this package conflict.
      attr_accessor :conflicts

      # What other packages does this package replace.
      attr_accessor :replaces

      # What other package(s) does this package provide the same dependency fulfilment.
      # For example, a package 'bar-plus' might fulfill the same dependency criteria
      # as package 'bar', so 'bar-plus' is said to provide 'bar'.
      attr_accessor :provides

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

      # Homepage
      attr_accessor :homepage

      # Location of central vcs repository.
      attr_accessor :repository

      #######################
      # Calculated Defaults #
      #######################

      def release=(date)
        @release = Time.parse(date.strip)
      end

      # Project name defaults to package name.
      def project
        @project ||= package
      end

      # Title defaults to package name captialized.
      def title
        @title ||= package.capitalize
      end

      # Summary will default to the first sentence or line
      # of the full description.
      def summary
        @summary ||= (
          if description
            i = description.index(/(\.|$)/)
            i = 69 if i > 69
            description.to_s[0..i]
          end
        )
      end

      # Limit summary to 69 characters.
      def summary=(line)
        @summery = line[0..69]
      end

      #
      def extensions
        @extensions ||= (
          Dir.glob('ext/**/extconf.rb')
        )
      end

      # Executables default to the contents of bin/.
      def executables
        @executables ||= (
          rootfolder.glob('bin/*').collect{ |bin| File.basename(bin) }
        )
      end

      # Contace defaults to the first author.
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
      def loadpath=(paths)
        @loadpath = list(paths)
      end

      #
      def authors=(auths)
        @authors = list(auths)
      end

      #
      def requires=(x)
        @requires = x.to_list
      end

      #
      def recommends=(x)
        @recommends = x.to_list
      end

      #
      def suggests=(x)
        @suggests = x.to_list
      end

      #
      def conflicts=(x)
        @conflict = x.to_list
      end

      #
      def replaces=(x)
        @replaces = x.to_list
      end

      #
      def provides=(x)
        @provides = x.to_list
      end


      ###########
      # Aliases #
      ###########

      alias_accessor :name       , :package
      alias_accessor :date       , :release

      alias_accessor :brief      , :summary
      alias_accessor :abstract   , :description

      alias_accessor :require    , :requires
      alias_accessor :depend     , :requires  # old terminology
      alias_accessor :dependency , :requires  # old terminology

      alias_accessor :recommend  , :recommends
      alias_accessor :suggest    , :suggests
      alias_accessor :conflict   , :conflicts
      alias_accessor :provide    , :provides
      alias_accessor :replace    , :replaces

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

      #def exclude=(x)
      #  @exclude = list(x)
      #  @exclude << 'admin' #unless app.configuration.file?
      #  @exclude
      #end

      # Package name is generally in the form of +name-version+, 
      # or +name-version-platform+ if +platform+ is specified.
      #
      # TODO: Improve buildno support ?
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

      ############
      # VALIDATE #
      ############

      def valid?
        return false unless name
        return false unless version
        return false unless contact
        return false unless description
        #return false unless homepage
      end

      def assert_valid
        raise "no name"        unless name
        raise "no version"     unless version
        raise "no contact"     unless contact
        raise "no description" unless description
        #raise "no homepage"    unless homepage
      end

      #
      def to_s
        to_yaml
      end

      ###
      #def method_missing(name, *args)
      #  name = name.to_s
      #
      #  super if block_given?
      #  super if !args.empty?
      #  super if !metafolder
      #
      #  file = meta + name
      #  if file.exist?
      #    add_attribute(name, file.read)
      #  else
      #    super
      #  end
      #end

    private

      def add_attribute(name, value)
        (class << self; self; end).class_eval do
          attr_accessor name
        end
        send("#{name}=", value)
      end

      # TODO: Use String#to_list instead (?)
      def list(l)
        case l
        when String
          l.split(/[:;\n]/)
        else
          [l.to_a].flatten.compact
        end
      end

    end#class Metadata

  end#class Project

end#module Reap

