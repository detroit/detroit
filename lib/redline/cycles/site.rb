module Redline

  # = Website Life Cycles
  #
  lifecycle :site do

    cycle :prepare,
          :generate,
          :analyize,
          :document,
          :release

    cycle :reset,
          :clean

  end

end

