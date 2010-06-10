# = TITLE:
#
#   Setup DSL
#
# = SYNOPSIS:
#
#   Mixen used to setup a package, eg. a manual install.
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
module Reap
module Utils

  # = Setup DSL
  #
  # Setup utilities provides a convenient way to install
  # a ruby project via setup.rb.

  module Setup

    # Installation to a prefix destination using setup.rb.
    # Some package types may need this.

    def prefix_install(prefix)
      mkdir_p(prefix)

      unless setup_rb
        raise "Setup.rb is missing. Forced to abort."
      end
      # mock install
      cmd = ''
      cmd << 'ruby setup.rb '
      cmd << '-q ' unless project.verbose?
      cmd << 'config --installdirs=std ; '
      cmd << 'ruby setup.rb '
      cmd << '-q ' unless project.verbose?
      cmd << "install --prefix=#{prefix}"
      sh cmd
    end

    # If setup.rb is not found add a copy to the project.
    # FIXME

    def setup_rb
      unless File.exist?('setup.rb')
        f = File.join(libdir,'vendor','setup.rb')
        if File.exist?(f)
          cp(f,'.')
        else
          raise "setup.rb is not avaialble"
        end
      end
      true
    end

    #     # Setup and install. This builds and installs a project
    #     # using setup.rb or install.rb. If neither exist setup.rb
    #     # will be created for the purpose.
    #     #
    #     #     options    Command line options to add to shell command.
    #     #     script     Install script, default is install.rb or setup.rb
    #     #--
    #     #     source     Location of source. (Defaults to current directory)
    #     #++
    #
    #     def setup(keys={})
    #
    #       options = keys['options']
    #       script  = keys['script']
    #       #source = keys.source || Dir.pwd
    #
    #       options = [options].flatten.compact
    #
    #       if script
    #         exe = script + ' '
    #         exe << options.join(' ')
    #       elsif File.exist?('install.rb')
    #         exe = 'ruby install.rb '
    #         exe << options.join(' ')
    #       elsif File.exist?('setup.rb') or setup_rb
    #         exe = 'ruby setup.rb '
    #         exe << '-q ' unless verbose?
    #         exe << options.join(' ')
    #         exe << ' all'
    #       else
    #         puts "Script setup.rb or install.rb is missing."
    #         return nil
    #       end
    #
    #       # SHELLS OUT!
    #
    #       #Dir.chdir(source) do
    #         #begin
    #           success = sh(exe)
    #           puts "Installation complete!" if success
    #         #rescue Errno::EACCES
    #         #  puts "Permission denied"
    #         #  exit -1
    #         #end
    #       #end
    #     end

  end

end
end
