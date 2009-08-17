#!/usr/bin/env ruby

PKG_TITLE = 'WhiteCloth'
PKG_NAME = 'whitecloth'
PKG_VERSION = '1'
PKG_AUTHOR = 'Thomas Sawyer'
PKG_EMAIL = 'transami@runbox.com'
PKG_SUMMARY = 'WhiteCloth is an implementation of ArtML'
PKG_DESCRIPTION = 'WhiteCloth is a Ruby implementation of ArtML'

# site info
# remark out if you don't need
PKG_HOMEPAGE = 'http://whitecloth.rubyforge.org'
PKG_RUBYFORGE_PROJECT = 'whitecloth'
PKG_RUBYFORGE_PASS = nil

# all package files
PKG_FILES = [ 'lib/**/*', 'test/**/*', 'samples/**/*', 'doc/**/*', '[A-Z]*', 'Rakefile' ]

# rdoc
RDOC_TITLE = PKG_TITLE
RDOC_DIR = 'doc'
RDOC_TEMPLATE = 'kilmer'
RDOC_OPTIONS = ''
RDOC_INCLUDE = [ 'VERSION', 'README', 'CHANGELOG', 'TODO', 'COPYING', 'lib/**/*.rb', 'bin/**/*.rb' ]
RDOC_EXCLUDE = []

# include in distribution
PKG_DIST_DIRS = [ 'bin', 'lib', 'test', 'samples' ]
PKG_DIST_FILES = [ 'README', 'TODO', 'CHANGELOG', 'VERSION', 'LICENSE', 'Rakefile' ]

# tests
PKG_TEST_DIR = 'test'
PKG_TEST_FILES = [ 'test/*_test.rb', 'test/**/*_test.rb' ]

=begin
# library files for manual install
PKG_LIB_DIR = 'lib'
PKG_LIB_MKDIRS = '**/*/'
PKG_LIB_FILES = [ '**/*.rb', '**/*.yaml' ]
PKG_LIB_DEPRECATE = []

# binary files for manual install
PKG_BIN_DIR = 'bin'
PKG_BIN_FILES = '**/*'
PKG_BIN_DEPRECATE = []
=end

#***************************************************************************
# The PackMule Rakefile v0.1
# PackMule can run tests, build packages and gems, manually install,
# generate rdocs, and publish them. CVS support might be added later.
#
# In general, layout your project directory as follows:
#   - lib/
#   - lib/#{lib_name}/       if you need a lib dir
#   - bin/              
#   - test/                  
#   - demo/ -or- examples/ -or- samples/
#   - doc/ -and;or- rdoc/
# The test dir can have subdirs, but tests should be named 
# like '#{name}_test.rb' or 'test_#{name}.rb'.
#
# Then use the Rake.yaml config file designed for this form.
# To get a blank config for this form type:
#   > rake form
# This will send the form to stdout.  There may be a line like
# "(in ...)" at the beginning, just remove it or remark it.
#***************************************************************************

require 'rake'
require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

#################################################
# load config from Rake.yaml and make constants #
#################################################
#YAML::load( File.open('Rake.yaml') ).each{|c,v| self.class.const_set(c,v)}


##
# = Default Task
##

desc "Default Task (test)"
task :default => [ :test ]


##
# = Run Unit Tests
##

Rake::TestTask.new("test") { |t|
  #t.desc "Run all tests"
  t.libs << PKG_TEST_DIR
  PKG_TEST_FILES.each { |pat| t.pattern = pat }
  t.verbose = true
}


##
# = Genereate RDoc Documentation
##

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = RDOC_DIR
  rdoc.template = RDOC_TEMPLATE
  rdoc.title    = RDOC_TITLE
  rdoc.options << '--line-numbers --inline-source ' + RDOC_OPTIONS
  rdoc.rdoc_files.include(*RDOC_INCLUDE)
  rdoc.rdoc_files.exclude(*RDOC_EXCLUDE)
  rdoc.rdoc_files.delete_if { |f| ! File.exist?(f) }
}


##
# = Publish Documentation
##

# Publish documentation
#desc "Publish the API documentation"
#task :pdoc => [:rdoc] do 
#  Rake::SshDirPublisher.new("david@hunter.5th.dk", "sites/rubyonrails.org/ar", "doc").upload
#end

if PKG_RUBYFORGE_PROJECT
  desc "Publish to RubyForge"
  task :rubyforge do
      Rake::RubyForgePublisher.new(PKG_RUBYFORGE_PROJECT, PKG_RUBYFORGE_PASS).upload
  end
end


##
# = Create Compressed Packages
##

dist_dirs = PKG_DIST_DIRS

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = PKG_SUMMARY
  s.description = PKG_DESCRIPTION

  s.files = PKG_DIST_FILES
  dist_dirs.each do |dir|
    s.files.concat Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "CVS" ) }
  end
  #s.files.delete "test/fixtures/fixture_database.sqlite"
  s.require_path = 'lib'
  s.autorequire = '#{PKG_NAME}'
  s.has_rdoc = true
  s.author = PKG_AUTHOR
  s.email = PKG_EMAIL
  s.homepage = PKG_HOMEPAGE if PKG_HOMEPAGE
  s.rubyforge_project = PKG_RUBYFORGE_PROJECT if PKG_RUBYFORGE_PROJECT
end
  
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end


##
# = Line Count
##

desc "Line Count"
task :lines do
  lines = 0
  codelines = 0
  Dir.foreach("lib/#{PKG_NAME}") { |file_name| 
    next unless file_name =~ /.*rb/

    f = File.open("lib/#{PKG_NAME}/" + file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
  }
  puts "Lines #{lines}, LOC #{codelines}"
end


=begin
##
# = Manual Install
##

desc "Manual Installation"
task :install do
  
  # install
  # this was adapted from active record's install.rb
  # by way of rdoc's install.rb
  # by way of Log4r's install.rb 
  # with some modifications from ruby-gems' install.rb ;)
  
  require 'rbconfig'
  require 'find'
  require 'ftools'
  require 'fileutils'
  
  include Config
  
  #$sitedir = CONFIG["sitelibdir"]
  #unless $sitedir
  #  version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
  #  $libdir = File.join(CONFIG["libdir"], "ruby", version)
  #  
  #  $sitedir = $:.find {|x| x =~ /site_ruby/ }
  #  if !$sitedir
  #    $sitedir = File.join($libdir, "site_ruby")
  #  elsif $sitedir !~ Regexp.quote(version)
  #    $sitedir = File.join($sitedir, version)
  #  end
  #end
  
  $srcdir = CONFIG["srcdir"]
  $version = CONFIG["MAJOR"]+"."+CONFIG["MINOR"]
  $libdir = File.join(CONFIG["libdir"], "ruby", $version)
  $bindir = CONFIG['bindir']
  $archdir = File.join($libdir, CONFIG["arch"])
  $sitedir = CONFIG["sitelibdir"]
  if !$sitedir
    $sitedir = $:.find {|x| x =~ /site_ruby$/}
    if !$sitedir
      $sitedir = File.join($libdir, "site_ruby")
    elsif $sitedir !~ Regexp.new(Regexp.quote($version))
      $sitedir = File.join($site_libdir, $version)
    end
  end
  
  # get current dir
  current_dir = Dir.pwd
    
  ### install lib files
  
  if FileTest.directory?(PKG_LIB_DIR)
  
    # change dir to package lib dir
    Dir.chdir(PKG_LIB_DIR)
  
    # make lib dirs in ruby sitelibdir
    makedirs = FileList[*PKG_LIB_MKDIRS].to_a
    makedirs.each {|f| File::makedirs( File.join( $sitedir, *f.split(/\//) ) ) }
  
    # deprecated files that should be removed
    deprecated = FileList[*PKG_LIB_DEPRECATE].to_a

    # files to install in library path
    files = FileList[*PKG_LIB_FILES].to_a
  
    # the actual gruntwork
    File::safe_unlink *deprecated.collect{|f| File.join($sitedir, f.split(/\//))}
    files.each do |f| 
      File::install(f, File.join($sitedir, *f.split(/\//)), 0644, true)
    end
  
    # change dir back
    Dir.chdir(current_dir)

  end
    
  ### install bin files
  
  if FileTest.directory?(PKG_BIN_DIR)
  
    # change dir to package bin dir
    Dir.chdir(PKG_BIN_DIR)
  
    is_windows_platform = CONFIG["arch"] =~ /dos|win32/i
  
    # files to install in bin path
    files = FileList[*PKG_BIN_FILES].to_a
  
    # deprecated files that should be removed
    deprecated = FileList[*PKG_BIN_DEPRECATE].to_a
    
    # the actual gruntwork
    File::safe_unlink *deprecated.collect{|f| File.join($bindir, f.split(/\//))}
    files.each do |f|
      target = File.join($bindir, *f.split(/\//))
      File::install(f, target, 0755, true)
      if is_windows_platform
        File.open("#{target}.cmd", "w") do |file|
          file.puts "@ruby #{target} %1 %2 %3 %4 %5 %6 %7 %8 %9"
        end
      end
    end
  
    # change dir back
    Dir.chdir(current_dir)
  
  end
=end
  
end
