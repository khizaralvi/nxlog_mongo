include_recipe 'nxlog::default'

#Output destination
nxlog_destination 'MongoDBLogs' do
  output_module 'om_tcp'
  host '10.42.14.216'
  port 28017
  action :create
end

#Input source
nxlog_source "File" do
  input_module "im_file"
  save_pos true
if node["platform"] == "redhat"
  file "/u00/mongo/log/*.log"
  exec "$message = $raw_event; $Hostname = \'#{node['hostname']}\'; $filename = file_name(); to_json();"
elsif node["platform"] == "centos"
  file "/u00/mongo/log/*.log"
  exec "$message = $raw_event; $Hostname = \'#{node['hostname']}\'; $filename = file_name(); to_json();"
elsif node["platform"] =="windows"
  file "C:/MongoLogs/mongo.log"
end 	
destination ['MongoDBLogs']  	
end