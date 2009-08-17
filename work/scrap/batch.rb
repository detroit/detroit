# = TITLE:
#
#   Batch DSL
#
# = COPYING:
#
#   Copyright (c) 2007 Psi T Corp.
#
#   This file is part of the ProUtils' Reap program.
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

#require 'yaml'
#require 'rbconfig'  # replace with facets/rbsystem in future ?

#require 'reap/dsl/batch/task'
#require 'reap/dsl/batch/build'
#require 'reap/dsl/batch/directory'

module Reap
module Dsl

  # Batch module defines the DSL for calling other batch files
  # and system binaries.

  module Batch

    # Abort running.
    #def abort(msg=nil)
    #  puts msg if msg
    #  exit 0
    #end

    def root_directory
      @root_directory ||= Dir.pwd
    end

    def call_directory
      @call_directory ||= File.expand_path(File.dirname($0))
    end

    # TODO Better name? (system_directory ?)

    def batch_directory
      # TODO: Better definition?
      @batch_directory ||= (
        dir = call_directory.sub(root_directory + '/', '').split('/').first
        File.join(root_directory, dir)
      )
    end

    # If a system directory is used (as opposed to a local project directory)
    # then the batch directory will need to be set explicitly.

    attr_writer :batch_directory

    # Current batch file, relative to the batch directory.

    def batch_file
      File.expand_path($0).sub(batch_directory + '/', '')
    end

    # Run batch file and cache result.
    #
    # Usually this can be taken care of by method_missing.
    # But, in some cases, built in method names block batch
    # calls, so you have to use #batch to invoke those.

    def batch(batchfile, arguments=nil)
      batch_cache[batchfile] ||= batch!(batchfile, arguments)
    end

    # Lauch a batch file. Like #batch but not-cached.
    # Run a batch file.
    # TODO: How to handle arguments?

    def batch!(batchfile, arguments=nil)
      #BatchFile.new(batchfile).call # Old way with batch execution context object.

      @main = nil  # reset main task

      script = File.read($0 = batchfile)
      eval(script, TOPLEVEL_BINDING, $0)

      #batch_file = File.expand_path($0).sub(batch_directory + '/', '')
      #run(batch_file)
      run_main #(batch_file)
    end

    # Is a path a local batch directory?

    def batch_directory?(path)
      b = File.join(File.dirname($0), path.to_s)
      b if FileTest.directory?(b)
    end

    # Is a file a local batch file?

    def batch?(path)
      b = File.join(File.dirname($0), path.to_s)
      b if FileTest.file?(b) && FileTest.executable?(b)
    end

    # Is a batch run complete or in the process of being completed?
    # Has the batch file been executed before?

    def done?(batchfile)
      batchfile == $0 || batch_cache.key?(batchfile)
    end

    # Batch cache, which prevents batch runs from re-executing.

    def batch_cache
      @batch_cache ||= {}
    end

    # If method is missing try to run an external task
    # or binary by that name. If it is a binary, arguments
    # translate into commandline parameters. For example:
    #
    #   tar 'foo/', :x=>true, :v=>true, :z=>true, :f=>'foo.tar.gz'
    #
    # or
    #
    #   tar '-xvzf', "foo.tar.gz", "foo/"
    #
    # becomes
    #
    #   tar -x -v -z -f foo.tar.gz foo/
    #
    # If it is a task, it will be cached. Tasks only ever run once.
    # To run them more than once you can manually execute them with #run.
    # Likewise you can manually run and cache by calling #batch.
    # This is good to know, b/c in some cases built in method names
    # block task calls, so you have to #batch to invoke them.

    def method_missing(sym,*args)
      puts "method_missing: #{sym}" if debug?
      #begin
        launch(sym,*args)
      #rescue ArgumentError
      #  super
      #end
    end

    # Luanch a (batch) script.

    def launch(name, *args)
      name  = name.to_s
      force = name.chomp!('!')

      # is this a batch directory?
      if batch_directory?(name)
        return Batch::Space.new(self, name)
      end

      params = args.to_params

      # is this a batch file?
      if bat = batch?(name)
        if force
          cmd = "./#{bat} #{params}"
          puts "--> non-cached execution: #{cmd}" if trace?
          return batch!(bat, args)
        else
          if done?(bat)
            return nil unless bin?(name)  # return cache?
          else
            cmd = "./#{bat} #{params}"
            puts "--> cached execution: #{cmd}" if trace?
            return batch(bat, args)
          end
        end
      end

      # is this a bin file?
      if bin = bin?(name)
        cmd = "#{File.basename(bin)} #{params}"
        return sh(cmd)
      end

      raise ArgumentError, "script not found -- #{name}"
    end

  end

  # This is a type of functor, that allows for calling batch files
  # that are in subdirectories using "dir.file" notation. Eg.
  #
  #   svn.log
  #
  # could run the svn/log reap file.

  class Batch::Space
    private *instance_methods.select{ |m| m !~ /^__/ }

    def initialize(manager, directory)
      @manager   = manager
      @directory = directory
    end

    def method_missing(sym, *args)
      path = File.join(@directory, sym.to_s)
      @manager.launch(path, *args)
    end
  end

end
end
