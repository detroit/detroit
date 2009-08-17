module Reap

  # = Site Pipeline
  #
  pipeline :site do
    phase :configure
    phase :generate => :configure
    phase :document => :generate
    phase :release  => :document

    phase :reset
    phase :clean => :reset
  end

end
