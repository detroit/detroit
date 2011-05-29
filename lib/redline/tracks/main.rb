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
          :publish,    # publish documentation/website
          :release,    # release packages / deploy to servers(?)
          :announce    # tell the world about your awesome work

    route :reset,      # mark artifacts as out-of-date
          :clean,      # remove temporary artifacts
          :purge       # remove all generate files

  end

end

