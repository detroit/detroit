require 'detroit'

module Detroit

  ##
  # The standard toolchain encompasses the set of tools typically used in 
  # the workflow for building a software project. Since that is the primary
  # design goal of Detroit, it is consquently the *standard* toolchain.
  #
  # A ToolChain instance is a module. To register a tool for use with the
  # tool chain simply include it into the tool class.
  #
  # @example
  #   class Faux < Tool
  #     include Standard
  #     ...
  #
  # @todo Not sure about the name `promote` for the last stage. Is there a 
  #       better name? Perhaps `announce` or `market`?
  #
  Standard = ToolChain.new do

    line :prepare,    # prepare services / ensure service requirements
         :generate,   # code generation
         :compile,    # compile source code
         :test,       # run tests and specifications
         :analyze,    # perform code analysis
         :document,   # generate documentation
         :package,    # create packages
         :install,    # install the package locally (if need be)
         :verify,     # post package verification / integration tests
         :publish,    # publish website/documentation
         :release,    # release packages
         :deploy,     # deploy system to servers
         :promote     # tell the world about your awesome work

    line :reset,      # mark all by products as out-of-date
         :clean,      # remove temporary by products
         :purge       # remove all by products

  end

end

