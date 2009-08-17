require 'reap/project/scm'

module Reap

  class Project

    # Update all logs.

    def log(*args)
      log_changes(*args)
      log_notes(*args)
    end

    # Generate ChangeLog. This routes to the
    # source control manager library.

    def log_changes(options=nil)
      options = configure_options(options, 'log-changes', 'log')
      scm_log(options)
    end

    # TODO: Add ability to read header notes.

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
    # TODO: Remove format field, and ultimately use XML as primary format?

    def log_notes(options={})
      options = configure_options(options, 'log-notes', 'log')

      loadpath = options['loadpath'] || metadata.loadpath
      labels   = options['labels']   || ['TODO', 'FIXME', 'OPTIMIZE']
      output   = options['output']   || 'log'

      loadpath = list_option(loadpath)

      labels = labels.split(',') if String === labels
      labels = [labels].flatten.compact

      output.chomp!('/')

      records, counts = log_notes_extract(labels, loadpath)
      notes = log_notes_format(labels, records, (format=nil))

      if records.empty?
        puts "No #{labels.join(', ')} notes."
      else
        files_saved = log_notes_save(output, notes, labels)
        files_saved.each do |file|
          puts "Updated #{file}"
        end
        puts counts.collect{|l,n| "#{n} #{l}s"}.join(', ')
      end
    end

    private

    # Gather notes.

    def log_notes_extract(labels, loadpath=nil)
      files = multiglob_r(*loadpath)

      counts = Hash.new(0)
      records = []

      files.each do |fname|
        next unless fname =~ /.*rb/      # TODO should this be done?
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

    # Format notes.

    def log_notes_format(labels, records, format=nil)
      #return "No #{labels.join('/')} notes." if records.empty?
      #return {} if records.empty?
      notes = {}
      labels.each do |label|
        recs = records.select{ |r| r['label'] == label }
        next if recs.empty?
        out = "\n= #{label}\n"
        last_file = nil
        recs.sort!{ |a,b| a['file'] <=> b['file'] }
        recs.each do |record|
          if last_file != record['file']
            out << "\n"
            last_file = record['file']
            out << "== file://#{record['file']}\n"
          end
          out << "* #{record['note'].rstrip} (#{record['line']})\n"
        end
        notes[label] = out
      end
      return notes
    end

    # Save notes.

    def log_notes_save(dir, notes, labels)
      files_saved = []
      mkdir_p(dir)
      # Remove empty note files.
      (labels - notes.keys).each do |label|
        file = File.join(dir,label)
        rm(file) if File.file?(file)
      end
      # Create note files.
      notes.each do |label, note|
        file = apply_naming_policy(label, 'rdoc')
        file = File.join(dir,file)
        if dryrun?
          puts "write #{file}"
        else
          files_saved << file
          File.open(file,'w') do |f| f << note end      
        end
      end
      return files_saved
    end

    #

    def naming_policy
      @naming_policy ||= (
        logconfig = settings['log'] || {}
        policy = logconfig['policy'] || ['down', 'ext']
        list_option(policy)
      )
    end

    # TODO: Naming policy needs to be apply to changelog too.

    def apply_naming_policy(name, ext)
      naming_policy.each do |policy|
        case policy
        when /^low/, /^down/
          name = name.downcase
        when /^up/
          name = name.upcase
        when /^cap/
          name = name.capitalize
        when /^ext/
          name = name + ".#{ext}"
        end
      end
      name
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
