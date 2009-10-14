module Syckle

  # = Special Announcement Cycle
  #
  lifecycle :attn do

    cycle :prepare,
          :generate,
          :promote

    cycle :reset,
          :clean

  end

end

