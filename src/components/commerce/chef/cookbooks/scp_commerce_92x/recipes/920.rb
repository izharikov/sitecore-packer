scp_commerce_92x_920 'Prepare for Sitecore Commerce installation' do
  options Chef::Mixin::DeepMerge.deep_merge(node['scp_commerce_92x']['common'], node['scp_commerce_92x']['920'])
  secrets node['scp_sitecore_common']['secrets']
  action :prepare
end

scp_commerce_92x_920 'Install Sitecore Commerce' do
  options Chef::Mixin::DeepMerge.deep_merge(node['scp_commerce_92x']['common'], node['scp_commerce_92x']['920'])
  install_storefront false
  action :install
end

scp_commerce_92x_920 'Post-installation Sitecore Commerce steps' do
  options Chef::Mixin::DeepMerge.deep_merge(node['scp_commerce_92x']['common'], node['scp_commerce_92x']['920'])
  action :postinstall
end
