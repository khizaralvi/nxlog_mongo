
include_recipe 'nxlog::default'

#Output destination
nxlog_destination 'SQLServerLogs' do
  output_module 'om_tcp'
  host '10.42.14.216'
  port 28018
  action :create
end

#Input source
nxlog_source "WindowsLogs" do
  input_module "im_msvistalog"
  save_pos true
  query "<QueryList><Query Id=\"0\"><Select Path=\"Application\">*</Select><Select Path=\"System\">*</Select><Select Path=\"Microsoft\-Windows\-FailoverClustering/Diagnostic\">*</Select></Query></QueryList>" 
  exec "$message = $raw_event; $Hostname = \'#{node['hostname']}\'; to_json(); if ($channel == \"Application\" and $SourceName != \"MSSQLSERVER\") {drop();} if ($channel == \"System\" and $SourceName != \"Microsoft-Windows\-FailoverClustering\") {drop();}"
destination ['SQLServerLogs']  	
end
