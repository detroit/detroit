# Global Runtime Configuration.

require 'rc/api'

module Detroit
  def self.rc_config
    @rc_config ||= []
  end
end

RC.setup 'detroit' do |config|
  Detroit.rc_config << config
end

