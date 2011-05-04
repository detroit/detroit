module Redline

  # Main track.
  track :main do

    route :prepare,    # prepare services / ensure service requirements
          :generate,   # code generation
          :compile,    # compile source code
          :test,       # run tests and/or specifications
          :analyize,   # run code analysis
          :document,   # generate documentation
          :package,    # create packages
          :verify,     # post package verification (eg. integration tests)
          :release,    # release packages / deploy to servers?
          :promote     # tell the world about you awesome work

    route :reset,
          :clean

  end

end

