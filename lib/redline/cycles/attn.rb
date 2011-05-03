module Syckle

  # = Special Announcement Cycle
  #
  lifecycle :attn do

    cycle :prepare,
          :generate,
          :announce

    cycle :reset,
          :clean

  end

end

