module Detroit

  # Define an assembly.
  #
  # @return nothing.
  def self.assembly(name, &block)
    ass = Assembly.new(name, &block)
    const_set(name, ass)
  end

  # Map of toolchain names to classes.
  #
  # @return [Hash<Symbol,Class>] All defined assemblies.
  def self.assemblies
    @assemblies ||= {}
  end

  ##
  # An *assembly* is a set of production lines where each line is a list
  # of named work stations.
  #
  class Assembly < Module

    def initialize(name, &block)
      Detroit.assemblies[name.to_s.downcase.to_sym] = self

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
      tool_class.assembly = self
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
