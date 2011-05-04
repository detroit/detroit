module Redline

  # The Attention track consists of two routes. The name-sake route:
  #
  #   prepare -> generate -> announce
  #
  # The the usual maintainence route:
  #
  #   reset -> clean
  #
  track :attn do

    route :prepare,
          :generate,
          :announce

    route :reset,
          :clean

  end

end

