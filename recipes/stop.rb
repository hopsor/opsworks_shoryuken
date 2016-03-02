# Adapted from nginx::stop: https://github.com/aws/opsworks-cookbooks/blob/master/nginx/recipes/stop.rb

include_recipe "opsworks_shoryuken::service"

node[:deploy].each do |application, deploy|

  unless node[:shoryuken][application]
    next
  end

  execute "stop Rails app #{application}" do
    command "sudo monit stop -g shoryuken_#{application}_group"
  end

end
