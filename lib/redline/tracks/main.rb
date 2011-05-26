module Redline

  # Main track.
  track :main do

    route :prepare,    # prepare services / ensure service requirements
          :generate,   # code generation
          :compile,    # compile source code
          :test,       # run tests and/or specifications
          :analyze,    # run code analysis
          :document,   # generate documentation
          :package,    # create packages
          :verify,     # post package verification
          :release,    # release packages / deploy to servers(?)
          :announce    # tell the world about your awesome work

    route :reset,
          :clean

  end

end

