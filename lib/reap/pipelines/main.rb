module Reap

  # = Main Pipeline
  #
  # TODO: Change name of +reset+ to something better?
  pipeline :main do
    phase :configure
    phase :generate => :configure
    phase :analyize => :generate
    phase :compile  => :analyize
    phase :validate => :compile
    phase :document => :validate
    phase :package  => :document
    phase :release  => :package
    phase :promote  => :release
    phase :archive  => :promote

    phase :reset
    phase :clean => :reset
    #phase :pristine => :clean
  end

end

