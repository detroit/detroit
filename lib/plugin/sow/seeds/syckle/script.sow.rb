#!/usr/bin/env ruby

about "Scaffold a Syckle-ready Ruby project."

usage "--syckle[=<package-name>]"

argument(:package) do |val|
  val = val || pathname
  raise ArgumentError, "Package name required." unless val
  raise ArgumentError, "Package name must be a single word." unless /^\w+$/ =~ val
  metadata.name = val
end

scaffold do
  copy "**/[A-Z]*"
  copy "lib"
  #copy "README.till", '.', :verbatim=>true
end

#component :test do
#  copy 'test'
#end

#component :bin do
#  copy 'bin'
#end

#component :site do
#  copy 'site'
#end

