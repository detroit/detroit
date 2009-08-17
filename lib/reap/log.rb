require 'reap/plugin'

module Reap

  # = Log
  #
  # The Log class provides a common and easy to use means for
  # different services to log there activity.
  #
  class Log #< Plugin

    attr :project
    attr :file

    #
    def initialize(domain, filename)
      @domain   = domain
      @project  = domain.project
      @file     = filename
      #super(domain, key)
    end

    #
    def method_missing(s, *a, &b)
      @domain.send(s, *a, &b)
    end

    # Write to log file.
    def write(str)
      mkdir_p(File.dirname(file)) #unless File.file?(file)
      File.open(file, 'w'){ |f| f << str }
    end
    alias_method :<<, :write

    #
    def append(str)
      mkdir_p(File.dirname(file)) #unless File.file?(file)
      File.open(file, 'a'){ |f| f << str }
    end

    #
    def clear
      File.open(file, 'w'){ |f| f << '' } if File.file?(file)
    end

    #
    def outofdate?(*sources)
      FileUtils.outofdate?(file.to_s, sources.flatten)
    end

    #
    def uptodate?(*sources)
      FileUtils.uptodate?(file.to_s, sources.flatten)
    end

  end

end

