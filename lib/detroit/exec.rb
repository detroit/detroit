module Detroit

  # Execute a sepcific detroit tool.
  #
  # Note this uses the executable gem to automatically
  # "cli-ify" a tool class.
  #
  def self.tool_exec(*argv)
    require 'executable'

    tool, stop = argv.shift.split(':')     

    raise "No tool specified." unless tool
    raise "No tool stop specified." unless stop

    begin
      require "detroit-#{tool}"
    rescue LoadError
      raise "Unknown tool. Perhaps try `gem install detroit-#{tool}`."
    end

    tool_class = Detroit.tools[tool]

    exec_class = Class.new(tool_class) do
      include Executable

      # TODO: Fix executable, to at least super if defined super.
      define_method(:initialize) do
        tool_class.instance_method(:initialize).bind(self).call
      end

      # Show this message.
      def help!
        cli.show_help
        exit
      end
      alias :h! :help!

      define_method(:call) do |*args|
        if assemble?(stop.to_sym)
          assemble(stop.to_sym)
        else
          raise "#{tool} does not know how to #{stop}."
        end
      end
    end

    #exec_class.send(:define_method, :command_name) do
    #  tool
    #end

    exec_class.run(argv)
  end

end
