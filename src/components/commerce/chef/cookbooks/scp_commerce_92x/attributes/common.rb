default['scp_commerce_92x']['common'] = {
  'install' => {
    'cert_path' => 'c:/certificates',
    'tmp' => 'c:/tmp',
    'root' => 'c:/tmp/sitecore',
    'windows_user_name' => 'vagrant',
    'windows_user_password' => 'vagrant',
  },
  'sql' => {
    'server_name' => 'localhost',
    'admin_user' => 'sa',
    'admin_password' => 'Vagrant42',
  },
  'solr' => {
    'root' => 'C:/tools/solr-7.5.0',
    'service' => 'SOLR',
    'url' => 'https://localhost:8983/solr',
  },
  'sitecore' => {
    'prefix' => 'sc9',
    'site_hostname' => 'sc9.local',
    'site_url' => 'https://sc9.local',
    'site_path' => 'c:/inetpub/wwwroot/sc9.local',
    'identityserver_hostname' => 'sc9.identityserver',
    'xconnect_hostname' => 'sc9.xconnect',
  },
  'commerce' => {
    'port_biz' => '4200',
    'port_ops' => '5015',
    'storefront_hostname' => 'sc9.commerce',
    'storefront_url' => 'https://sc9.commerce',
  },
}
