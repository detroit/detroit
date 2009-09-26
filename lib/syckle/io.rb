require 'ratch/io'
require 'ansi/terminal'
require 'ansi/code'

module Syckle

  # = Syckle IO
  #
  # The IO class is used to cleanly separate out the
  # basic input/output "dialog" between user and script.
  #
  class IO < ::Ratch::IO

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

  private

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
