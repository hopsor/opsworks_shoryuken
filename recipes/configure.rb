# Adapted from rails::configure: https://github.com/aws/opsworks-cookbooks/blob/master/rails/recipes/configure.rb

include_recipe "deploy"
include_recipe "opsworks_shoryuken::service"

node[:deploy].each do |application, deploy|

  unless node[:shoryuken][application]
    next
  end

  execute "restart Shoryuken app #{application}" do
    cwd deploy[:current_path]
    command node[:shoryuken][application][:restart_command]
    action :nothing
  end

  node.default[:deploy][application][:database][:adapter] = OpsWorks::RailsConfiguration.determine_database_adapter(application, node[:deploy][application], "#{node[:deploy][application][:deploy_to]}/current", force: node[:force_database_adapter_detection])
  deploy = node[:deploy][application]

  template "#{deploy[:deploy_to]}/shared/config/database.yml" do
    source "database.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      database: deploy[:database],
      environment: deploy[:rails_env]
    )

    notifies :run, "execute[restart Shoryuken app #{application}]"

    only_if do
      deploy[:database][:host].present? && File.directory?("#{deploy[:deploy_to]}/shared/config/")
    end
  end

end
