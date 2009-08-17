require 'reap/plugin'

module Reap
class Plugin

  # = Host Plugin Base Class
  #
  # Base class for Host Services.
  class HostPlugin < Plugin

    README = "readme{,.txt}"
    RELEASE = "{release,news,notes}{,.txt}"

    # Generic confirmation.
    #
    def confirm?(action, options={})
      return true if force?
      ans = ask("#{action.to_s.capitalize} to #{self.class.basename.downcase}?", "yN")
      case ans.downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    # Create an announcement.
    #
    def announcement(file=nil, options={})
      header = options[:header]

      if file = Dir.glob(file, File::FNM_CASEFOLD).first
        ann = File.read(file)
      else
        readme_file  = Dir.glob(README, File::FNM_CASEFOLD).first
        release_file = Dir.glob(RELEASE, File::FNM_CASEFOLD).first

        ann = []

        if readme_file
          readme = File.read(readme_file).strip
          if release_file
            # read release file and strip
            release = File.read(release_file).strip
            # remove header if release file has one
            release.sub!(/^.*?$/, '') if release[0,1] == '='
            # sub in for release where the readme referes to it
            readme.sub!(/^Please see (the)? RELEASE file.*?$/, release.strip)
          end
          ann << readme
        else
          if header and not release_file
            ann << "#{metadata.title} #{metadata.version} has been released."
            ann << ''
            ann << "  #{metadata.homepage}"
            ann << ''
            ann << "#{metadata.abstract}"
            ann << ''
          end
          if release_file
            ann << File.read(release_file)
          end
        end
        ann = ann.join("\n")
      end
      ann.unfold_paragraphs
    end

    #def announce_confirm?(options={})
    #  return true if force?
    #  ans = ask("Announce to #{self.class.basename.downcase}?", "yN")
    #  case ans.downcase
    #  when 'y', 'yes'
    #    true
    #  else
    #    false
    #  end
    #end

    # Generic announce confirmation.

    #def release_confirm?(options={})
    #  return true if force?
    #  ans = ask("Release to #{self.class.basename.downcase}?", "yN")
    #  case ans.downcase
    #  when 'y', 'yes'
    #    true
    #  else
    #    false
    #  end
    #end

  end

end
end

