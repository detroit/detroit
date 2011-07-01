module Detroit

  # Standard assembly is the default. In the majority of cases this
  # is all that will be needed. It represents the workflow of
  # a developing project (particularly Ruby project).
  assembly_system :standard do

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
      :promote     # tell the world about your awesome work

    # The site track is a subset of the main track used to
    # isolate the distribution of documentation and uploading
    # a project's website. 
    #
    #   prepare -> generate -> analyze -> document -> publish
    #
    track :site,
      :prepare,
      :generate,
      :analyze,
      :document,
      :publish

    # The attention track is a small subset of main track, used to
    # isolate the sending of promotional materials, mainly release
    # announcements.
    #
    #   prepare -> generate -> promote
    #
    track :attn,
      :prepare,
      :generate,
      :promote

  end

end
