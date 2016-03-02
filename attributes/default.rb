include_attribute 'deploy'

default[:shoryuken] = {}

node[:deploy].each do |application, deploy|
  unless node[:shoryuken][application]
    next
  end
  default[:shoryuken][application.intern] = {}
  default[:shoryuken][application.intern][:restart_command] = "sudo monit restart -g shoryuken_#{application}_group"
  default[:shoryuken][application.intern][:syslog] = false
  default[:shoryuken][application.intern][:syslog_ident] = nil
end
