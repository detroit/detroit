module Detroit

  # Define a toolchain.
  #
  # @return nothing.
  def self.toolchain(name, &block)
    tc = Toolchain.new(name, &block)
    const_set(name, tc)
  end

  # Map of toolchain names to classes.
  #
  # @return [Hash<String,Class>] toolchains.
  def self.toolchains
    @toolchains ||= {}
  end

  ##
  # A Toolchain is a set of production lines where each line is a list
  # of named stations.
  #
  # TODO: This used to be called an `Assembly`, maybe it was a better name?
  #
  class Toolchain < Module

    def initialize(name, &block)
      Detroit.toolchains[name.to_s.downcase.to_sym] = self

      @lines = []
      @tools = []

      super(&block) #module_eval(&block)
    end

    # Returns a list of lists of stops.
    #
    # @return [Array<Array<Symbol>>] lines.
    def lines
      @lines
    end

    # Define a chain of named links.
    def line(*stations)
      # TODO: raise error if stage already used ?
      self.lines << stations.map{ |s| s.to_sym }
    end

    # Lookup a chain by a given stage name.
    #
    # @return nothing.
    def find(station)
      station = station.to_sym

      lines.find do |line|
        line.include?(station)
      end
    end

    # Add tool to toolchain.
    #
    # @return [Class] The tool class.
    def register_tool(tool_class)
      tool_class.toolchain = self
      @tools << tool_class
      Detroit.register_tool(tool_class)
    end

    # When the tool chain is included into a class, register
    # that class as a tool.
    #
    # @return [void] The tool class.
    def included(tool_class)
      register_tool(tool_class) unless @tools.include?(tool_class)
    end
  end

end
