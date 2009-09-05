__DIR__ = File.dirname(__FILE__)

Dir[File.join(__DIR__, 'core_ext', '*.rb')].each do |file|
  require file
end

