#!/usr/bin/env ruby

# = About
#
# Query infromation about reap settings and/or the current
# project.
#
# NOTE: This would have been #inspect but for the
# built-in method.

cmd "about this project"

def about(*args)

  #args = commandline.arguments[1..-1]

  if args.empty?
    puts
    puts "  #{metadata.title} #{metadata.version} (#{metadata.released})"
    puts "  #{metadata.abstract}"
    puts "  " + metadata.homepage
    puts
    puts "  " + metadata.description
    puts
    puts "  Copyright #{metadata.copyright}"
    puts
  else
    args.each do |field|
      case field
      when 'settings'
        y settings
      when 'metadata'
        y metadata
      else
        puts metadata.send(field)
      end
    end
  end

end

# = Compile
#
# compile extensions
#
#compilers.default.compile


# = Test
#
# Run test or spec suite.

cmd "run test suite"

def testrun
  unit_test
end

# = Generate documentation.

cmd "generate documentation"

def document
  service_rdoc.document
  service_ridoc.document
end

# = Package
#
# Create distribution packages.

cmd "create distribution packages"

def package

  clean

  formats = commandline.arguments[1..-1]

  if formats.empty?
    formats = config.formats || ['zip', 'gem']
  end

  formats.each do |format|
    file = send("package_#{format}")
  end

end

# = Publish
#
# publish website

cmd "publish website"

def publish

  if config.rubyforge
    rubyforge.publish
  end

end

desc "generate documentation"

opts "template", :string

def document(options)
  rdoc.document(:template=>options['template'])
  ridoc.document
end


# = Announce
#
# post release announcement(s)

task 'document' do

  desc 'generate documentation'

  opts "template", :string

  proc do |opts|
    rdoc.document
    ridoc.document
  end

end


# = Release
#
# release packages to hosts



