# Adapted from deploy::rails: https://github.com/aws/opsworks-cookbooks/blob/master/deploy/recipes/rails.rb

include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  unless node[:shoryuken][application]
    next
  end

  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping opsworks_shoryuken::deploy application #{application} as it is not an Rails app")
    next
  end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  Chef::Log.debug("Running opsworks_shoryuken::setup for application #{application}")
  node.set[:opsworks][:rails_stack][:recipe] = "opsworks_shoryuken::setup"
  node.set[:opsworks][:rails_stack][:restart_command] = node[:shoryuken][application][:restart_command]

  opsworks_rails do
    deploy_data deploy
    app application
  end

  Chef::Log.debug("Deploying Shoryuken Application: #{application}")
  opsworks_deploy do
    deploy_data deploy
    app application
  end

  Chef::Log.debug("Exposing app env vars into a file")
  template File.join(deploy[:deploy_to], "shared", "app.env") do
    source "app.env.erb"
    mode 0770
    owner deploy[:user]
    group deploy[:group]
    variables(
      :environment => OpsWorks::Escape.escape_double_quotes(deploy[:environment_variables])
    )
    only_if {File.exists?("#{deploy[:deploy_to]}/shared")}
  end

  Chef::Log.debug("Restarting Shoryuken Application: #{application}")
  execute "restart Rails app #{application}" do
    command "sleep 60 && #{node[:shoryuken][application][:restart_command]}"
    #command node[:shoryuken][application][:restart_command]
  end

end
