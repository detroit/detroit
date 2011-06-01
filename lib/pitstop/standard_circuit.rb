module Pitstop

  # Standard circuit is the default. In the vast majority of
  # cases this is all that will ever be used.
  circuit :standard do

    # Main track.
    #
    # TODO: Should :install comes before :verify b/c verfication might
    # require a local installation?
    track :main,
      :prepare,    # prepare services / ensure service requirements
      :generate,   # code generation
      :compile,    # compile source code
      :test,       # run tests and specifications
      :analyze,    # perform code analysis
      :document,   # generate documentation
      :package,    # create packages
      :verify,     # post package verification / integration tests
      :install,    # install the package locally (if need be)
      :publish,    # publish website/documentation
      :release,    # release packages
      :deploy,     # deploy system to servers
      :announce    # tell the world about your awesome work

    # The attention track is a small subset of main track.
    #
    #   prepare -> generate -> promote
    #
    track :attn,
      :prepare,
      :generate,
      :announce

    # The site track is a subset of the main track:
    #
    #   prepare -> generate -> analyze -> document -> publish
    #
    track :site,
      :prepare,
      :generate,
      :analyze,
      :document,
      :publish

  end

end
