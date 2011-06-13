## initialize

Load schedule text written in Ruby DSL.

    check do |ruby|
      Promenade::Schedule.new(ruby)
    end

    ok <<-HERE
      Email :myself do |s|
        s.mailto = 'transfire@gmail.com'
        s.active = true
      end

      Syntax do |s|
        s.exclude = ['lib/plugins']
        s.active  = false
      end
    HERE

Load schedule from a file written in Ruby DSL.

    check do |file|
      path = File.join(root_dir, file)
      Promenade::Schedule.new(File.new(path))
    end

    ok 'samples/example_schedule.rb'

Load schedule text written in YAML"

    check do |yaml|
      Promenade::Schedule.new(yaml)
    end

    ok <<-HERE
      ---
      myself:
        service: email
        mailto : transfire@gmail.com
        active : true
      end

      syntax:
        exclude: [lib/plugins]
        active : false
    HERE

Load schedule from a file written in YAML.

    check do |file|
      path = File.join(root_dir, file)
      Promenade::Schedule.new(File.new(path))
    end

    ok 'samples/example_schedule.yml'

