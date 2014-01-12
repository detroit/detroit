## initialize

Load toolchain script written in Ruby DSL.

    check do |ruby|
      Detroit::Toolchain::Script.new(ruby)
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

Load toolchain script from a file written in Ruby DSL.

    check do |file|
      path = File.join(root_dir, file)
      Detroit::Toolchain::Script.new(File.new(path))
    end

    ok 'samples/example_toolchain.rb'

Load toolchain script text written in YAML"

    check do |yaml|
      Detroit::Toolchain::Script.new(yaml)
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

Load toolchain script from a file written in YAML.

    check do |file|
      path = File.join(root_dir, file)
      Detroit::Toolchain::Script.new(File.new(path))
    end

    ok 'samples/example_toolchain.yml'

