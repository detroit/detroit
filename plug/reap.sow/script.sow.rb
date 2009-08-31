#!/usr/bin/env ruby

help "Create a Reap-ready Ruby project."

usage "reap [options] <name>"

argument(:package) do |val|
  raise ArgumentError, "Package name required." unless val
  raise ArgumentError, "Package name must be a single word." unless /^\w+$/ =~ val
  metadata.package = val
end

manifest do
  copy "**/*", '.'
  #copy "README.till", '.', :verbatim=>true
end

