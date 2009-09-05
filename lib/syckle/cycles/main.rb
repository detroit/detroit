module Syckle

  # = Main Lifecycles
  #
  lifecycle :main do
    cycle :configure, :generate, :analyize, :compile, :validate,
          :document, :package, :release, :promote, :archive

    cycle :reset, :clean
  end

end

