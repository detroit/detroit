module Redline

  # The website track is a subset of the main track with two routes:
  #
  #   prepare -> generate -> analyize -> document -> release
  #
  # And the usual maintainence route:
  #
  #   reset -> clean
  #
  track :site do

    route :prepare,
          :generate,
          :analyize,
          :document,
          :release

    route :reset,
          :clean

  end

end

