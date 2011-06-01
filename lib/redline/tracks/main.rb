module Redline

  # TODO: Should :install comes before :verify b/c verfication might
  # require a local installation?

  # Main track.
  track :main do

    route :prepare,    # prepare services / ensure service requirements
          :generate,   # code generation
          :compile,    # compile source code
          :test,       # run tests and specifications
          :analyze,    # perform code analysis
          :document,   # generate documentation
          :package,    # create packages
          :verify,     # post package verification / integration tests
          :install,    # install the package locally (if need be)
          :publish,    # publish documentation/website
          :release,    # release packages
          :deploy,     # deploy system to servers
          :announce    # tell the world about your awesome work

    route :reset,      # mark products as out-of-date
          :clean,      # remove temporary products
          :purge       # remove all generated products

  end

end

