module Redline

  # The website track is a subset of the main track with two routes:
  #
  #   prepare -> generate -> analyze -> document -> release
  #
  # And the usual maintainence route:
  #
  #   reset -> clean
  #
  track :site do

    route :prepare,
          :generate,
          :analyze,
          :document,
          :release

    route :reset,
          :clean

  end

end

