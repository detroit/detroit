#!/usr/bin/env ruby

newproject :reap do

  help "Scaffold a new Reap ready project."

  argument(:name, 'name of new project')

  script do
    abort "Project name argument required." unless name

    metadata.name = name

    template('**/*')
    #template("lib/name-", "lib/#{name}")
    #template("gen/lib/name-"   , "gen/lib/#{name}")
    #template("gen/lib/name-/*" , "gen/lib/#{name}/")
  end

end

