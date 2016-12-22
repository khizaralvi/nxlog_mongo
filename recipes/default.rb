#
# Cookbook Name:: nxlog
# Recipe:: default
#
# Copyright (C) 2014 Simon Detheridge
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform_family']
when 'debian'
  if node['platform'] == 'ubuntu'
    include_recipe 'nxlog::ubuntu'
  else
    include_recipe 'nxlog::debian'
  end
when 'rhel'
  include_recipe 'nxlog::redhat'
when 'windows'
  include_recipe 'nxlog::windows'
else
  Chef::Application.fatal!('Attempted to install on an unsupported platform')
end

package_name = node['nxlog']['installer_package']

  if "#{node.chef_environment}" == "STAGING_MONGO"
  bash 'install_nxlog' do
  user 'root'
  cwd '/etc'
  code <<-EOH
  export https_proxy=N7-SVC-PX002CL.PROD.NET.STARWAVE.COM:8080
  wget https://nxlog.co/system/files/products/files/1/nxlog-ce-2.9.1716-1_rhel6.x86_64.rpm --no-check-certificate
  EOH
  not_if do ::File.exists?("/etc/#{package_name}") end
end
elsif "#{node.chef_environment}" == "PROD_MONGO" or "PROD_MONGO_02" or "DEV_MONGO"
  bash 'download_nxlog' do
  user 'root'
  cwd '/etc'
  code <<-EOH
wget https://nexus.disney.com/nexus/content/repositories/ops-global-sedds-yum/disney/dds/misc/nxlog-agent/2.9.1716-1_rhel6.x86_64/nxlog-agent-2.9.1716-1_rhel6.x86_64.rpm --no-check-certificate
  EOH
  not_if do ::File.exists?("/etc/#{package_name}") end
end
end 

if platform?('ubuntu', 'debian')
  dpkg_package 'nxlog' do
    source "#{Chef::Config[:file_cache_path]}/#{package_name}"
    options '--force-confold'
  end
else 
  package 'nxlog' do
    source "/etc/#{package_name}"
    options "--nogpgcheck"
    not_if { ::File.exists?('/etc/random.txt') }
end
end

bash 'addNxlog_To_MongodGroup' do
user 'root'
cwd '/etc'
code <<-EOH
usermod -a -G mongod nxlog
EOH
end

service 'nxlog' do
  action [:enable, :start]
end

template "#{node['nxlog']['conf_dir']}/nxlog.conf" do
  source 'nxlog.conf.erb'

  notifies :restart, 'service[nxlog]', :delayed
end

directory "#{node['nxlog']['conf_dir']}/nxlog.conf.d"

# delete logging components that aren't converged as part of this chef run
zap_directory "#{node['nxlog']['conf_dir']}/nxlog.conf.d" do
  pattern '*.conf'
end

include_recipe 'nxlog::resources_from_attributes'
