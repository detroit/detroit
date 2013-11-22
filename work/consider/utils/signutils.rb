# = TITLE:
#
#   Sign DSL
#
# = COPYING:
#
#   Copyright (c) 2007,2008 Tiger Ops
#
#   This file is part of the Reap program.
#
#   Reap is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Reap is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Reap.  If not, see <http://www.gnu.org/licenses/>.
#
# = TODO:
#   - Do signitures belong under data/{name}/?
#     Heck do all these metadata files belong there?
#     OTOH using remote require, how would one access these?
#     should they be contigious to the libs themselves?

#require 'autorake/tasks/manifest'

#
module Reap
module Utilities

  # Create signitures for libraries.
  # FIXME

  module SignUtils

    # Default set of files to sign.
    DEFAULT_SIGN_FILES = ['lib/**/*', 'ext/**/*']

    DEFAULT_PUBLIC_KEY  = 'pubkey.pem'
    DEFAULT_PRIVATE_KEY = '_privkey.pem'

    # Generate file signitures. This task generates signitures
    # for each library file using public/private keys.
    # The sign script will generate encrypted signitures for
    # files in the project --by default the lib/ and ext/ files.
    #
    #   name       Project name [name]
    #   keyfile    Pathname to .pem file for private key
    #   files      Files to include/exclude.
    #   output     Directory to store signiture files
    #               [data/{name}/signitures/]
    #
    # By default the keyfile is '_privkey.pem'. (BE SURE NEVER
    # TO PUBLISH THIS FILE!!!) But if no a private key file is
    # given/found, this will ask if you would like to
    # generate one. It also can generate a public key for the
    # project if it does not have one.
    #
    # There are two ways to approach key usage here. Either
    # a per project key pair, or use a personal key pair.

    def sign( override=nil )
      name     = info.project
      keyfile  = info.private_key

      output   = info.sign_output
      files    = info.sign_files

      files    ||= DEFAULT_SIGN_FILES
      keyfile  ||= DEFAULT_PRIVATE_KEY
      output   ||= File.join('data',name,'signitures')

      files = Dir.multiglob_with_default(DEFAULT_SIGN_FILES, files)

      unless File.directory?( dir = File.dirname(output) )
        puts "Output directory #{dir} doesn't exist."
        return nil
      end

      output = File.expand_path(output)

      unless keyfile and File.exist?(keyfile)
        ans = ask("Private key file required. Generate one?", "yN")
        case ans
        when 'y', 'Y'
          keyfile = genkey(name)
          puts "\nFile '#{keyfile}' created. Be sure to keep this file private and secure."
        else
          puts "Task cancelled."
          exit -1
          #return nil
        end
      end

      keyfile = File.expand_path(keyfile)

      generate_signitures(keyfile, files, output)
    end

    private

    # Generate a signiture for a file.

    def generate_signitures( keyfile, files, to_folder )
      privkey = load_key(keyfile)

      dir = File.dirname(to_folder)
      save_key(privkey.public_key, File.join(dir, DEFAULT_PUBLIC_KEY))

      fu.mkdir_p(to_folder)
      files.each do |file|
        next if File.directory?(file)
        sig = sign_file(privkey, file)
        write_signiture(to_folder, file, sig)
      end
    end

    # Write signiture to file.

    def write_signiture( to_folder, file, sig )
      sigfile = File.join(to_folder, file + '.sig')
      fu.mkdir_p(File.dirname(sigfile))
      if project.dryrun?
        puts "(save #{sigfile})" unless project.quiet?
      else
        File.open( sigfile, 'w' ) do |f|
          f << sig
        end
      end
    end

    # Generate a signiture of a file.

    def sign_file( key, file )
      plain = File.read( file )
      dig = digester(info.digest||'sha256').new
      sig = key.sign(dig, plain)
      return sig
    end

    # Verify a signiture of a file.

    def verify_signiture?( pubkey, sig, plain )
      plain = plain.read if IO === plain
      dig = digester(info.digest||'sha256').new
      success = pubkey.verify(dig, sig, plain)
      return success
    end

    # Generate a public key from a private key.
    #
    #def pubkey( privkey )
    #  pubkey = privkey.public_key
    #  return pubkey
    #end

    # Load key.

    def load_key( file )
      key = OpenSSL::PKey::RSA.new(File.read(file))
    end

    # Save key.

    def save_key( key, file )
      if project.dryrun?
        puts "(save #{file})" unless project.quiet?
      else
        File.open( file, 'w' ) do |f|
          f << key.to_pem
        end
      end
    end

    # Generate a private key and save it to '_privkey.pem'.

    def genkey( name )
      key = OpenSSL::PKey::RSA.new(2048){ print "." } # @name }
      save_key( key, PRIVATE_KEY )
      return PRIVATE_KEY
    end

    #   def write_keypair( libname )
    #     privkey = genkey( libname )
    #     pubkey = privkey.public_key
    #     save_key( privkey, "privkey.pem" )
    #     save_key( pubkey, "pubkey.pem" )
    #     puts "Key pair generated. Please secure privkey.pem."
    #   end
    #
    #   # Generate a private key.
    #
    #   def genkey( libname='.' )
    #     key = OpenSSL::PKey::RSA.new(2048) { print "." } # libname }
    #     return key
    #   end
    #
    #   # Generate a public key from a private key.
    #
    #   def pubkey( privkey )
    #     pubkey = privkey.public_key
    #     return pubkey
    #   end

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

  #   def digester( type=nil )
  #     require 'openssl'
  #     type = 'sha256' unless type
  #     case type.to_s.downcase
  #     when 'md5'
  #       require 'digest/md5'
  #       Digest::MD5
  #     when 'sha128', 'sha1'
  #       require 'digest/sha1'  #need?
  #       OpenSSL::Digest::SHA1
  #     when 'sha256'
  #       require 'digest/sha1'  #need?
  #       OpenSSL::Digest::SHA256
  #     when 'sha512'
  #       require 'digest/sha1'  #need?
  #       OpenSSL::Digest::SHA512
  #     end
  #   end

  end

end
end
