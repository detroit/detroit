module Syckle

  # = Website Life Cycles
  #
  lifecycle :site do
    cycle :configure, :generate, :document, :release
    cycle :reset, :clean
  end

end

