#!/usr/bin/env ruby

# TODO Integrate file signing and general manifest better (?)
#
# TODO digester is in sign.rb too. Dry-up?
#
# TODO Is it problematic to add a digest to the manifest?

# Define manifest task.

def task_manifest( options={} )
  #file @output => @files do
  #  manifest
  #end

  desc "Generate package manifest"
  task :manifest do #=> [ @output ]
    project.manifest
  end

  desc "Verify the manifest"
  task :diff do
    project.verify_manifest
  end

  desc "Clobber non-manifest"
  task :clobber do
    project.clobber
  end

  project.ignore << (project.info.manifest || Project::DEFAULT_MANIFEST_FILE)
end


class Project

  # Default manifest filename.
  DEFAULT_MANIFEST_FILE = 'MANIFEST'

  # Create a MANIFEST file for this package. This script
  # produces a simple file manifest for a project,
  # listing the path of each file and and optional checksum.
  #
  # Generate manifest. By default it is a very simple filename
  # list. The +check+ type can be supplied and a checksum will
  # be given before each filename.
  #
  #     files    Files to include (can use + or - prefixes)
  #     output   Save the manifest to this file (otherwise stdout)
  #     digest   Include optional digest:
  #                 md5, sha128 (sha1), sha256, sha512

  def manifest
    output = manifest_file
    text   = build_manifest

    File.open(output, 'w+'){ |f| f << text }
    puts "#{output} saved." unless quiet?
  end

  #
  # Build manifest text.
  #

  def build_manifest
    digest = info.manifest_digest  #info.digest
    files  = info.files

    manifest = ''
    if digest
      files.each do |f|
        manifest << "#{hexdigest(f,digest)} #{f}\n"
      end
    else
      files.each do |f|
        manifest << "#{f}\n"
      end
    end
    return manifest
  end

  #
  # Verify manifest.
  #

  def verify_manifest
    output = manifest_file

    abort "No manifest file." unless output
    require 'find'
    temp = "#{output}~"
    list = build_manifest
    pass = nil

    File.open(temp, 'w'){ |f| f.puts list }
    begin
      r = `diff -du #{output} #{temp}`
      if pass = r.empty?
        case verbosity?
        when 'check'
          (print_justified('Manifest', '[PASS]'); puts) unless quiet?
        when 'quiet'
        else
          puts "Manifest is uptodate."
        end
      else
        checklist << :manifest
        puts r
      end
    ensure
      FileUtils.rm temp
    end
    return pass
  end

  #
  # Clobber non-manifest files.
  #

  def clobber
    keep = info.files(true) + [manifest_file]
    toss = Dir.glob('**/*') - keep
    puts toss.join("\n")
    ansr = ask("The above files will be removed. Continue?", "yN")
    case ansr.downcase
    when 'y', 'yes'
      toss.each{ |f| rm_r(f) if File.exist?(f) }
    else
      puts "Clobber task cancelled."
      exit!
    end
  end

  private

  def manifest_file
    if file = info.manifest
       file
    else
      apply_naming_policy(DEFAULT_MANIFEST_FILE, 'txt')
    end
  end

  # Produce hexdigest/cheksum for a file. Default digest type is sha256.

  def hexdigest( file, type=nil )
    digester(type).hexdigest(File.read(file))
  end

  # Return a digest class for given +type+.
  # Supported digests are:
  #
  # * md5
  # * sha1
  # * sha128  (same as sha1)
  # * sha256
  # * sha512
  #
  # Default digest type is sha256.

  def digester( type=nil )
    require 'openssl'
    case type.to_s.downcase
    when 'md5'
      require 'digest/md5'
      Digest::MD5
    when 'sha128', 'sha1'
      require 'digest/sha1'  #need?
      OpenSSL::Digest::SHA1
    when 'sha256'
      require 'digest/sha1'  #need?
      OpenSSL::Digest::SHA256
    when 'sha512'
      require 'digest/sha1'  #need?
      OpenSSL::Digest::SHA512
    end
  end

end



#     # Files/file pattern to include in manifest.
#     # Defaults to all files minus IGNORE.
#     attr_accessor :files
# 
#     # Save the manifest to this file (otherwise stdout)
#     attr_accessor :output
# 
#     # Include optional digest:
#     #     md5, sha128 (sha1), sha256, sha512
#     attr_accessor :digest
# 
#     # Create manifest and check_manifest tasks.
#     def initialize  # :yield: self
#       yield self if block_given?
# 
#       @output ||= DEFAULT_OUTPUT_FILE
#       @files  ||= ['**/*']
#       @files = [@files].flatten.compact
# 
#       # Collect files.
#       #f = []
#       #f += Dir.multiglob_with_default('**/*', *@files)
#       #f -= Dir.multiglob_r(IGNORE)
#       #f = f.select{ |x| File.file?(x) }
#       #f.sort
# 
#       IGNORE << @output
# 
#       files = []
#       files += Dir.multiglob_with_default('**/*', *@files)
#       files -= Dir.multiglob_r(IGNORE)
#       #files = files.select{ |x| File.file?(x) }
#       @files = files
# 
#       define
#     end
