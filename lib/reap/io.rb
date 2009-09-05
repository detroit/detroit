require 'ansi/terminal'
require 'ansi/code'

module Reap

  # = Reap IO
  #
  # The IO class is used to cleanly separate out the
  # basic input/output "dialog" between user and script.
  #
  class IO

    # DEPRECATE THIS IN FAVOR OF #REPORT (?)
    def status(message)
      puts message unless quiet?
    end

    #
    def report(message)
      puts message unless quiet?
    end

    #
    attr :commandline

    #
    def initialize(commandline)
      @commandline = commandline
    end

    def force?   ; commandline.force?   ; end
    def quiet?   ; commandline.quiet?   ; end
    def trace?   ; commandline.trace?   ; end
    def debug?   ; commandline.debug?   ; end
    def pretend? ; commandline.pretend? ; end

    # Internal status report.
    #
    # Only output if dryrun or trace mode.
    #
    def trace(message)
      if pretend? or trace?
        puts message
      end
    end

    # Convenient method to get simple console reply.
    #
    def ask(question, answers=nil)
      print "#{question}"
      print " [#{answers}] " if answers
      until inp = $stdin.gets ; sleep 1 ; end
      inp.strip
    end

    # Ask for a password. (FIXME: only for unix so far)
    #
    def password(prompt=nil)
      prompt ||= "Enter Password: "
      inp = ''
      $stdout << "#{prompt} "
      $stdout.flush
      begin
        #system "stty -echo"
        #inp = gets.chomp
        until inp = $stdin.gets
          sleep 1
        end
      ensure
        #system "stty echo"
      end
      return inp.chomp
    end

    def print(str='')
      super(str) unless quiet?
    end

    def puts(str='')
      super(str) unless quiet?
    end

    #
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

    #
    #
    def display_action(action_item)
      phase, service, action, parameters = *action_item
      puts "  %-10s %-10s %-10s" % [phase.to_s.capitalize, service.service_title, action]
      #status_line(service.service_title, phase.to_s.capitalize)
    end

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

    #
    def ansize(text, code)
      #return text unless text.color
      if PLATFORM =~ /win/
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
