require 'ansi/terminal'
require 'ansi/code'

module Redline

  # = Redline IO
  #
  # The IO class is used to cleanly separate out the
  # basic input/output "dialog" between user and script.
  #
  class IO

    #
    attr :cli

    attr :stdout
    attr :stderr
    attr :stdin

    #
    def initialize(cli, stdout=nil, stderr=nil, stdin=nil)
      @cli = cli
      @stdout = stdout || $stdout
      @stderr = stderr || $stderr
      @stdin  = stdin  || $stdin
    end

    def force?   ; cli.force?   ; end
    def quiet?   ; cli.quiet?   ; end
    def verbose? ; cli.verbose? ; end

    def trace?   ; cli.trace?   ; end
    def trial?   ; cli.trial?   ; end
    def debug?   ; cli.debug?   ; end

    # TODO: deprecate in favor of #report ?
    def status(message)
      stderr.puts message unless quiet?
    end

    # Internal report. Only output if in TRACE mode.
    # TODO: rename to #warn ?
    def trace(message)
      stderr.puts message if verbose?
    end

    # Convenient method to get simple console reply.
    def ask(question)
      stdout.print "#{question} "
      stdout.flush
      input = stdin.gets #until inp = stdin.gets ; sleep 1 ; end
      input.strip
    end

    ## Ask for a password. (FIXME: only for unix so far)
    #def password(prompt=nil)
    #  prompt ||= "Enter Password: "
    #  inp = ''
    #  stdout << "#{prompt} "
    #  stdout.flush
    #  begin
    #    #system "stty -echo"
    #    #inp = gets.chomp
    #    until inp = $stdin.gets
    #      sleep 1
    #    end
    #  ensure
    #    #system "stty echo"
    #  end
    #  return inp.strip
    #end

    # TODO: Until we have better support for getting input across
    # platforms, we are using #ask for passwords too.
    def password(prompt=nil)
      prompt ||= "Enter Password: "
      ask(prompt)
    end

    #
    def print(str=nil)
      stdout.print(str.to_s) unless quiet?
    end

    #
    def puts(str=nil)
      stdout.puts(str.to_s) unless quiet?
    end

    # DEPRECATE: just use #puts
    def report(message)
      stdout.puts message unless quiet?
    end

##
    #
    def printline(left, right='', options={})
      return if quiet?

      separator = options[:seperator] || options[:sep] || ' '
      padding   = options[:padding]   || options[:pad] || 0

      left, right = left.to_s, right.to_s

      left_size  = left.size
      right_size = right.size

      #left  = colorize(left)
      #right = colorize(right)

      l = padding
      r = -(right_size + padding)

      style  = options[:style] || []
      lstyle = options[:left]  || []
      rstyle = options[:right] || []

      left  = lstyle.inject(left) { |s, c| ansize(s, c) }
      right = rstyle.inject(right){ |s, c| ansize(s, c) }

      line = separator * screen_width
      line[l, left_size]  = left  if left_size != 0
      line[r, right_size] = right if right_size != 0

      line = style.inject(line){ |s, c| ansize(s, c) }

      puts line + ansize('', :clear)
    end

##
    #
    #
    def display_action(action_item)
      phase, service, action, parameters = *action_item
      puts "  %-10s %-10s %-10s" % [phase.to_s.capitalize, service.service_title, action]
      #status_line(service.service_title, phase.to_s.capitalize)
    end

##
    #
    #
    def status_header(left, right='')
      left, right = left.to_s, right.to_s
      #left.color  = 'blue'
      #right.color = 'magenta'
      unless quiet?
        puts
        print_header(left, right)
        #puts "=" * io.screen_width
      end
    end

##
    #
    #
    def status_line(left, right='')
      left, right = left.to_s, right.to_s
      #left.color  = 'blue'
      #right.color = 'magenta'
      unless quiet?
        puts
        #puts "-" * io.screen_width
        print_phase(left, right)
        #puts "-" * io.screen_width
        #puts
      end
    end

    #
    def print_header(left, right)
      if ANSI::SUPPORTED
        printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
        printline(left, right, :pad=>2, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
        printline('', '', :pad=>1, :sep=>' ', :style=>[:negative, :bold], :left=>[:bold], :right=>[:bold])
      else
        printline(left, right, :pad=>2, :sep=>'=')
      end
    end

    #
    def print_phase(left, right)
      if ANSI::SUPPORTED
        printline(left, right, :pad=>2, :sep=>' ', :style=>[:on_white, :black, :bold], :left=>[:bold], :right=>[:bold])
      else
        printline(left, right, :pad=>2, :sep=>'-')
      end
    end

  private

    #
    def ansize(text, code)
      #return text unless text.color
      if RUBY_PLATFORM =~ /win/
        text.to_s
      else
        ANSI::Code.send(code.to_sym) + text
      end
    end

    #
    def screen_width
      #Clio::ConsoleUtils.screen_width
      ANSI::Terminal.terminal_width
    end

  end

end
