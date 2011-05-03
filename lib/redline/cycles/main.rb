module Redline

  # = Main Life Cycles
  #
  lifecycle :main do

    cycle :prepare,    # prepare services / ensure service requirements
          :generate,   # code generation
          :compile,    # compile source code
          :test,       # run tests and/or specifications
          :analyize,   # run code analysis
          :document,   # generate documentation
          :package,    # create packages
          :verify,     # post package verification (eg. integration tests)
          :release,    # release packages / deploy to servers?
          :promote     # tell the world about you awesome work

    cycle :reset,
          :clean

  end

end
