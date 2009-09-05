module Syckle

  # = Special Announcement Cycle
  #
  lifecycle :attn do
    cycle :configure, :generate, :promote
    cycle :reset, :clean
  end

end

