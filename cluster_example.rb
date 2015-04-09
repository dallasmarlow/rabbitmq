if node['rabbitmq']['enable_auto_clustering']
  # if the current node matches the rmq clustered naming convention
  # of rmq<cluster id>-<node id> and the <node id> value is greater than 0
  # attempt to join a cluster with rmq<cluster id>-0
  fqdn_match = node['fqdn'].match(/^rmq\d-(\d)\./)
  if fqdn_match and fqdn_match.captures.first != '0'
    cluster_host = node['fqdn'].split('.').first.split('-').first + '-0'
    rabbitmq_cluster 'rabbit@' + cluster_host do
      action :join_cluster
      only_if 'grep ' + cluster_host + '$ /etc/hosts'
    end
  end
end