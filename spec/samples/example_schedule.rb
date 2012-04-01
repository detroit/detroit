Announce do |s|
  s.mailto = 'transfire@gmail.com'
  s.active = true
end

Gem do |s|
  s.autospec = true
  s.active   = true
end

DNote do |s|
  s.priority = -1
  s.active   = true
end

RDoc do |s|
  s.tracks  = 'site'
  s.format  = 'newfish'
  s.include = [ 'lib', '[A-Z]*' ]
  s.exclude = [ 'Redfile', 'lib/plugins/sow' ]
  s.extra   = nil
end

RI do |s|
  s.exclude = [ 'lib/plugins/sow' ]
  s.active  = true
end

Stats do |s|
  s.priority = -1
  s.active   = true
end

Syntax do |s|
  s.exclude = ['plug/sow/seeds']
  s.active  = false
end

Turn do |s|
  s.active = false
end

Testrb do |s|
  s.active = true
end

Yard do |s|
  s.active = false
end

#Rubyforge :rubyforge,
#  service: forge,
#  sitemap: {
#    site: syckle 
#  },
#  active: false

