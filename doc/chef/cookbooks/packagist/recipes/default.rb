require_recipe "apt"
require_recipe "apache2"
require_recipe "apache2::mod_php5"
require_recipe "mysql"
require_recipe "mysql::server"
require_recipe "php"
require_recipe "php::module_mysql"
require_recipe "git"

# disable apache2 default
execute "disable-default-site" do
  command "sudo a2dissite default"
  notifies :reload, resources(:service => "apache2"), :delayed
end

# install web_app
web_app "packagist" do
  template "packagist.conf.erb"
  notifies :reload, resources(:service => "apache2"), :delayed
end

# bin/vendors install
execute "run bin/vendors install" do
  command "#{node['vagrant']['directory']}/bin/vendors install"
end

# parameters.yml
template "#{node['vagrant']['directory']}/app/config/parameters.yml" do
  source "parameters.yml.erb"
  variables ({
  	:root_password => node['mysql']['server_root_password']
  })
end

# create database
execute "run app/console doctrine:database:create" do
  command "#{node['vagrant']['directory']}/app/console doctrine:database:create"
end

# doctrine:schema:create
execute "run app/console doctrine:schema:update" do
  command "#{node['vagrant']['directory']}/app/console doctrine:schema:update --force"
end

# install assets
execute "run app/console assets:install web" do
  command "#{node['vagrant']['directory']}/app/console assets:install #{node['vagrant']['directory']}/web --symlink"
end

#install solr
package "solr-jetty" do
  action :install
end

template "/etc/default/jetty" do
  source "jetty.erb"
end