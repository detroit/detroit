#!/usr/bin/env ruby

# LOG 2007-01-09 <transfire@gmail.com> Updated changelog to generate from comments in SMC::None.

# TODO Need to create unified ChangeLog class to DRY-up changelog creation by SCMs.

require 'facets/core/module/basename'

class Project

  # Define scm tasks.

  def task_scm
    type = project.scm

    desc "Update changelog (#{type})"
    task :changelog do
      project.changelog
    end

    desc "Version stamp (#{type})"
    task :version do
      project.stamp
    end
  end

  #

  DEFAULT_VERSION_FILE   = 'VERSION'
  DEFAULT_CHANGELOG_FILE = 'CHANGES'

  # Version stamp of project.

  def stamp
    #keys = info.select(:version, :status, :released, :version_file=>:revision_stamp)

    version      = info.version
    status       = info.status
    version_file = info.revision_stamp

    released     = Time.now.strftime("%Y-%m-%d") #keys['released']

    if TrueClass === version_file
      version_file = DEFAULT_VERSION_FILE
    end
    version_file ||= DEFAULT_VERSION_FILE

    if version = calculate_version
      stamp = format_version_stamp(version,status,released)
      if version_file and not dryrun?
        puts stamp
        write_version( stamp, version_file )
      else
        puts stamp
      end
    else
      puts "Can't calculate version."
    end
  end

  # Produce a changelog.

  def changelog
    changelog_file = info.revision_changelog
    changelog_file ||= DEFAULT_CHANGELOG_FILE

    if log = calculate_changelog
      if changelog_file and not dryrun?
        write_changelog( log, changelog_file )
      else
        puts log
      end
    else
      raise "indeterminite revision control system"
    end
  end

  # SCM Type

  def scm
    SCM.repository.basename
  end

  private

  # Write version stamp to file.

  def write_version( stamp, file )
    if File.directory?(file)
      file = File.join( file, DEFAULT_VERSION_FILE )
    end
    File.open(file,'w'){ |f| f << stamp }
    puts "#{file} saved."
  end

  # Write the ChangeLog to file.

  def write_changelog( log, file )
    if File.directory?(file)
      file = File.join( file, DEFAULT_CHANGELOG_FILE )
    end
    File.open(file,'w+'){ |f| f << log }
    puts "Change log written to #{file}."
  end

  # Format the version stamp.

  def format_version_stamp( version, status=nil, date=nil )
    if date.respond_to?(:strftime)
      date = date.strftime("%Y-%m-%d")
    else
      date = Time.now.strftime("%Y-%m-%d")
    end
    status = nil if status.to_s.strip.empty?
    stamp = []
    stamp << version
    stamp << status if status
    stamp << "(#{date})"
    stamp.join(' ')
  end

  # Various SCM Module Plugins

  module SCM

    def self.repository
      scm = nil
      constants.each do |c|
        s = const_get(c)
        if s.respond_to?(:repository?)
          if s.send(:repository?)
            scm = s
            break
          end
        end
      end
      return scm || Manual
    end

    #--
    #  __  __   _   _  _ _   _  _   _
    # |  \/  | /_\ | \| | | | |/_\ | |
    # | |\/| |/ _ \| .` | |_| / _ \| |__
    # |_|  |_/_/ \_\_|\_|\___/_/ \_\____|
    #
    #++
    # This provides (weak) versioning tasks for project's
    # without an SCM.
    #
    #    "This little piggy got none."
    #                       -- This Little Piggy

    module Manual
      def self.repository?
        false
      end

      def calculate_version
        #n = (Time.now - Time.parse(info.created)) / (60*60*24)
        #Time.now.strftime("%y.%m.%d")
        info.version
      end

      def calculate_changelog
        log = ''
        labels = ['LOG','CHANGE']
        records, counts = extract_notes(labels)
        records.each do |record|
          log << "* #{record['note']} (#{record['line']})\n"
        end
        return "= ChangeLog\n\n#{log}"
      end
    end

    #--
    #  ___   _   ___  ___ ___
    # |   \ /_\ | _ \/ __/ __|
    # | |) / _ \|   / (__\__ \
    # |___/_/ \_\_|_\\___|___/
    #
    #++
    # Provide Darcs SCM revision tools.

    module Darcs

      # Is a darcs repository?

      def repository?
        File.directory?('_darcs')
      end
      module_function :repository?

      # List changes via darcs scm.

      def calculate_changelog
        raise "not a darcs repository" unless repository?

        style   = info.revision_changelog_style
        file    = info.revision_changelog
        project = info.project

        case style
        when 'compact'
          changes = `darcs changes` #--repo=#{@repository}`
          log = "= #{project} #{file}\n\n"
          log << " #{calculate_version}\n"
          changes.split("\n").each do |line|
            case line
            when /^\s*$/
            when /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/
            when /^\s*tagged/
              log << $'
              log << "\n"
            else
              log << line
              log << "\n"
            end
          end
        else
          log = `darcs changes` #--repo=#{@repository}`
        end

        return log
      end

      # Retrieve the "revision number" from the darcs tree.

      def calculate_version
        raise "not a darcs repository" unless repository?

        status = info.status

        changes = `darcs changes`
        count   = 0
        tag     = "0.0"

        changes.each("\n\n") do |change|
          head, title, desc = change.split("\n", 3)
          if title =~ /^  \*/
            # Normal change.
            count += 1
          elsif title =~ /tagged (.*)/
            # Tag.  We look for these.
            tag = $1
            break
          else
            warn "Unparsable change: #{change}"
          end
        end
        ver = "#{tag}.#{count.to_s}"

        return ver
        #format_version_stamp(ver, status) # ,released)
      end

    end

    # TODO SVN
  end

  scm = SCM.repository
  include scm if scm
end




=begin
  # Name of project.
  attr_accessor :project

  # File to store ChangeLog.
  attr_accessor :changelog_file

  # Style of ChangeLog.
  attr_accessor :changelog_style

  # File to store VERSION stamp.
  attr_accessor :version_file

  # Project status. This is used to augment version stamp.
  attr_accessor :status

  ## When there's no SCM these are filled manually.

  # Project status. This is used to augment version stamp.
  attr_accessor :version

  # Project status. This is used to augment version stamp.
  attr_accessor :released
=end