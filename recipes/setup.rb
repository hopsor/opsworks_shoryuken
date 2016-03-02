# Adapted from unicorn::rails: https://github.com/aws/opsworks-cookbooks/blob/master/unicorn/recipes/rails.rb

include_recipe "opsworks_shoryuken::service"

# setup shoryuken service per app
node[:deploy].each do |application, deploy|

  unless node[:shoryuken][application]
    next
  end

  case node['platform_family']
  when 'rhel', 'fedora'
    monit_conf_dir = '/etc/monit.d'
  when 'debian'
    monit_conf_dir = '/etc/monit/conf.d'
  end

  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping opsworks_shoryuken::setup application #{application} as it is not a Rails app")
    next
  end

  opsworks_deploy_user do
    deploy_data deploy
  end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  directory "#{deploy[:deploy_to]}/shared/assets" do
    group deploy[:group]
    owner deploy[:user]
    mode 0775
    action :create
    recursive true
  end

  # Allow deploy user to restart workers
  template "/etc/sudoers.d/#{deploy[:user]}" do
    mode 0440
    source "sudoer.erb"
    variables :user => deploy[:user]
  end

  if node[:shoryuken][application]

    workers = node[:shoryuken][application].to_hash.reject {|k,v| k.to_s =~ /restart_command|syslog/ }
    config_directory = "#{deploy[:deploy_to]}/shared/config"

    workers.each do |worker, options|

      # Convert attribute classes to plain old ruby objects
      config = options[:config] ? options[:config].to_hash : {}
      config.each do |k, v|
        case v
        when Chef::Node::ImmutableArray
          config[k] = v.to_a
        when Chef::Node::ImmutableMash
          config[k] = v.to_hash
        end
      end

      # Generate YAML string
      yaml = YAML::dump(config)

      # Convert YAML string keys to symbol keys for shoryuken while preserving
      # indentation. (queues: to :queues:)
      yaml = yaml.gsub(/^(\s*)([^:][^\s]*):/,'\1:\2:')

      (options[:process_count] || 1).times do |n|
        file "#{config_directory}/shoryuken_#{worker}#{n+1}.yml" do
          mode 0644
          action :create
          content yaml
        end
      end
    end

    template "#{monit_conf_dir}/shoryuken_#{application}.monitrc" do
      mode 0644
      source "shoryuken_monitrc.erb"
      variables({
        :deploy => deploy,
        :application => application,
        :workers => workers,
        :syslog_ident => node[:shoryuken][application][:syslog_ident],
        :syslog => node[:shoryuken][application][:syslog]
      })
      notifies :reload, resources(:service => "monit"), :immediately
    end

  end
end
