#require 'erb'

module Reap

  # = Announcement 
  #
  # Announcment class is used to generate an announcement message.
  # By default this is a Release Announcment.

  class Announcement

    # Project metadata

    attr_accessor :metadata

    attr_accessor :cutoff

    attr_accessor :template

    #

    def initialize(options={}, &block)
      populate(options, &block)

      @cutoff   ||= 30
      @template ||= "{ANNOUNCE}{,.txt}"
    end

    # Make a release announcement. Generates and can email a release
    # announcements. These are nicely formated message and can
    # email the message to the specified address(es).
    #
    # The following settings apply:
    #
    #     template     Announcement file/template.
    #     cutoff       Max number of lines of changelog to show.
    #
    # A template file can be specified that uses "$setting" as
    # substitutes for poject information.

    def message
      template = Dir.glob(template(), File::FNM_CASEFOLD).first

      if template
        readme = File.read(template)
        readme = unfold_paragraphs(readme)
      else
        readme = ''
        #readme << "= #{metadata.title} v#{metadata.version}\n\n"
        readme << "#{metadata.description}\n\n"
        readme << "#{metadata.homepage}\n\n"
        readme << "Please see the NOTES file.\n\n"
        readme << "Please see the CHANGES file.\n"
      end

      # changelog
      file   = Dir.glob('change{s,log}{,.txt}', File::FNM_CASEFOLD)[0]
      changelog = file ? File.read(file).strip : ''
      #changelog = unfold_paragraphs(changelog)
      changelog = changelog.split("\n")[0..cutoff].join("\n")
      unless changelog =~ /^=/
        changelog = "\n== Changes\n\n" + changelog
      end

      # noteslog
      file = Dir.glob('note{s,log}{,.txt}', File::FNM_CASEFOLD)[0]
      notelog  = file ? File.read(file).strip : ''
      notelog  = unfold_paragraphs(notelog)
      unless notelog =~ /^=/
        notelog = "\n== Release Notes\n\n" + notelog
      end

      # Strip tiny version zero.
      #if keys['version'] =~ /[.].*?[.]/
      #  keys['version'] = keys['version'].chomp('.0')
      #end

      # Make announcement message
      message = readme.dup

      #message.gsub!('$readme$', readme || '')
      message.sub!(/^\s*please\ see(\ the)?\ notes(.*?)$/i, "\n" + notelog) if notelog
      message.sub!(/^\s*please\ see(\ the)?\ change(.*?)$/i, "\n" + changelog) if changelog

      template = message.dup

      template.scan(/\$(\w+?)\$/m) do |key|
        #key   = key.strip
        name  = $1.strip #key[1..-1]
        if metadata.respond_to?(name.downcase)
          value = metadata.send(name.downcase)
          message.gsub!("$#{name}$", value.to_s.strip)
        else
          puts "Warning: Unknown project metadata field -- #{name}."
        end
      end

      message.gsub!(/(^|[ ])[$].*?(?=[ ]|$)/,'') # remove unused vars
      message.gsub!(/\n\s*\n\s*\n/m,"\n\n")      # remove any triple blank lines
      message.rstrip!
 
      message = "\n" + message

      return message
    end

    #

    def unfold_paragraphs(string)
      blank = false
      text  = ''
      string.split(/\n/).each do |line|
        if /\S/ !~ line
          text << "\n\n"
          blank = true
        else
          if /^(\s+|[*])/ =~ line 
            text << (line.rstrip + "\n")
          else
            text << (line.rstrip + " ")
          end
          blank = false
        end
      end
      return text
    end


    def to_s
      message
    end

  end

end

