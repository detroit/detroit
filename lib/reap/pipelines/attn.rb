module Reap

  # = Special Announcement Pipeline
  #
  pipeline :attn do
    phase :configure
    phase :generate => :configure
    phase :promote  => :generate

    phase :reset
    phase :clean => :reset
  end

end

