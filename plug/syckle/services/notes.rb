require 'rexml/text'
#require 'reap/project/scm'

module Syckle::Plugins

  # = Development Notes Plugin
  #
  # This plugin goes through you source files and compiles
  # an lit of any labeled comments. Labels are single word
  # prefixes to a comment ending in a colon. For example,
  # you might note somewhere in your code:
  #
  #   TODO: Need to improve on the following code!
  #
  # By default this plugin supports the TODO, FIXME,
  # OPTIMIZE and DEPRECATE labels.
  #
  # Output is a set of files in XML and RDoc's simple
  # markup format.
  #
  # TODO: Add ability to read header notes. They oftern
  # have a outline format, rather then the single line.
  #
  # TODO: Do we need to generate HTML? Or just an XSL file?
  #
  class Notes < Service

    cycle :main, :document
    cycle :main, :reset
    cycle :main, :clean

    #available do |project|
    #  true
    #end

    # Default note labels to look for in source code.
    DEFAULT_LABELS = ['TODO', 'FIXME', 'OPTIMIZE', 'DEPRECATE']

    # Paths to search.
    attr_accessor :loadpath

    # Labels to document. Defaults are: TODO, FIXME, OPTIMIZE and DEPRECATE.
    attr_accessor :labels

    # Directory to save output. Defaults to standard log directory.
    attr_accessor :output

    # Format (xml, html, text).
    # TODO: HTML format is not usable yet.
    #attr_accessor :format

    #
    def initialize_defaults
      @loadpath = metadata.loadpath || 'lib'
      @output   = project.log + 'notes'
      @labels   = DEFAULT_LABELS
      #@format   = 'xml'
    end

    # Collect embedded notes.
    #
    # This task scans source code for developer notes and writes to
    # well organized files. This tool can lookup and list TODO, FIXME
    # and other types of labeled comments from source code.
    #
    #   files    Glob(s) of files to search.
    #   labels   Labels to search for. Defaults to [ 'TODO', 'FIXME' ].
    #   output   Output directory. Defaults to log/.
    #
    def document
      loadpath = self.loadpath
      labels   = self.labels
      output   = self.output
      #format   = self.format

      loadpath = loadpath.to_list

      labels = labels.split(',') if String === labels
      labels = [labels].flatten.compact

      records, counts = extract(labels, loadpath)
      records = organize(records)

      #case format.to_s
      #when 'rdoc', 'txt', 'text'
      #  text = format_rd(records)
      #else
      #  text = format_xml(records)
      #end

      if records.empty?
        status "No #{labels.join(', ')} notes."
      else
        %w{rdoc xml}.each do |format|
          text = format_records(records, format)
          file = log_notes_save(output, text, format)
          relfile = Pathname.new(file).relative_path_from(project.root)
          report "Updated #{relfile}"
        end
        report(counts.collect{|l,n| "#{n} #{l}s"}.join(', '))
      end
    end

    # Reset output directory, marking it as out-of-date.
    def reset
      if File.directory?(output)
        File.utime(0,0,output)
        report "reset #{output}"
      end
    end

    # Remove output directory.
    def clean
      if File.directory?(output)
        rm_r(output)
        status "reset #{output}"
      end
    end

    private

    # Gather notes. This returns two elements,
    # a hash in the form of label=>notes and a counts hash.
    #
    def extract(labels, loadpath=nil)
      files = multiglob_r(*loadpath)

      counts = Hash.new(0)
      records = []

      files.each do |fname|
        next unless File.file?(fname)
        next unless fname =~ /\.rb$/      # TODO should this be done?
        File.open(fname) do |f|
          line_no, save, text = 0, nil, nil
          while line = f.gets
            line_no += 1
            labels.each do |label|
              if line =~ /^\s*#\s*#{Regexp.escape(label)}[:]?\s*(.*?)$/
                file = fname
                text = ''
                save = {'label'=>label,'file'=>file,'line'=>line_no,'note'=>text}
                records << save
                counts[label] += 1
              end
            end
            if text
              if line =~ /^\s*[#]{0,1}\s*$/ or line !~ /^\s*#/ or line =~ /^\s*#[+][+]/
                text.strip!
                text = nil
                #records << save
              else
                text << line.gsub(/^\s*#\s*/,'')
              end
            end
          end
        end
      end
      return records, counts
    end

    # Organize records in heirarchical form.
    #
    def organize(records)
      orecs = {}
      records.each do |record|
        label = record['label']
        file  = record['file']
        line  = record['line']
        note  = record['note'].rstrip
        orecs[label] ||= {}
        orecs[label][file] ||= []
        orecs[label][file] << [line, note]
      end
      orecs
    end

    #
    def format_records(records, type=:rd)
      send("format_#{type}", records)
    end

    # Format notes in XML format.
    #
    def format_xml(records)
      xml = []
      xml << "<notes>"
      records.each do |label, per_file|
        xml << %[<set label="#{label}">]
        per_file.each do |file, line_notes|
          xml << %[<file src="#{file}">]
          line_notes.sort!{ |a,b| a[0] <=> b[0] }
          line_notes.each do |line, note|
            note = REXML::Text.normalize(note)
            xml << %[<note line="#{line}" type="#{label}">#{note}</note>]
          end
          xml << %[</file>]
        end
        xml << %[</set>]
      end
      xml << "</notes>"
      return xml.join("\n")
    end

    # Format notes in RD format.
    #
    def format_rdoc(records)
      out = []
      out << "= Development Notes"
      records.each do |label, per_file|
        out << %[\n== #{label}]
        per_file.each do |file, line_notes|
          out << %[\n=== file://#{file}]
          line_notes.sort!{ |a,b| a[0] <=> b[0] }
          line_notes.each do |line, note|
            out << %[* #{note} (#{line})]
          end
        end
      end
      return out.join("\n")
    end

    # Save notes.
    #
    def log_notes_save(dir, text, format)
      file = dir + "notes.#{format}"
      mkdir_p(file.parent)
      write(file, text)
      return file
    end

  end

end

  #     out = ''
  #
  #     case format
  #     when 'yaml'
  #       out << records.to_yaml
  #     when 'list'
  #       records.each do |record|
  #         out << "* #{record['note']}\n"
  #       end
  #     else #when 'rdoc'
  #       labels.each do |label|
  #         recs = records.select{ |r| r['label'] == label }
  #         next if recs.empty?
  #         out << "\n= #{label}\n"
  #         last_file = nil
  #         recs.sort!{ |a,b| a['file'] <=> b['file'] }
  #         recs.each do |record|
  #           if last_file != record['file']
  #             out << "\n"
  #             last_file = record['file']
  #             out << "file://#{record['file']}\n"
  #           end
  #           out << "* #{record['note'].rstrip} (#{record['line']})\n"
  #         end
  #       end
  #       out << "\n---\n"
  #       out << counts.collect{|l,n| "#{n} #{l}s"}.join(' ')
  #       out << "\n"
  #     end

  #     # List TODO notes. Same as notes --label=TODO.
  #
  #     def todo( options={} )
  #       options = options.to_openhash
  #       options.label = 'TODO'
  #       notes(options)
  #     end
  #
  #     # List FIXME notes.  Same as notes --label=FIXME.
  #
  #     def fixme( options={} )
  #       options = options.to_openhash
  #       options.label = 'FIXME'
  #       notes(options)
  #     end

