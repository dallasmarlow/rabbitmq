def cluster_contains_node?(cluster_node)
  Chef::Log.debug('rabbitmq_cluster: checking cluster status')
  cmd = Mixlib::ShellOut.new('rabbitmqctl cluster_status', :environment => {'HOME' => '/tmp'})
  cmd.run_command
  cmd.error!

  _, cluster_nodes = cmd.stdout.lines.map(&:chomp)
  if cluster_nodes
    cluster_nodes_matches = cluster_nodes.match(/\[\{nodes,\[(?:\{[\w]+),\[([^\]]+)\]\}/)
    if cluster_nodes_matches and not cluster_nodes_matches.captures.empty?
      cluster_nodes_matches.captures.first.split(',').map do |entry|
        entry.gsub("'", "")
      end.include?(cluster_node)
    end
  end
end

def record_cluster_node(cluster_node)
  node.set['rabbitmq']['cluster_node'] = cluster_node
  node.save
end

action :join_cluster do
  if node['rabbitmq']['cluster_node'] != new_resource.cluster_node
    case cluster_contains_node?(new_resource.cluster_node)
    when nil
      Chef::Log.warn('rabbitmq_cluster: unable to determine cluster membership status')
    when true
      Chef::Log.debug('rabbitmq_cluster: cluster_node is already a cluster member')
      record_cluster_node(new_resource.cluster_node)
    when false
      Chef::Log.info('rabbitmq_cluster: attempting to join cluster with node: ' + new_resource.cluster_node)
      join_cmd = 'rabbitmqctl join_cluster ' + new_resource.cluster_node
      join_cmd << ' -- ram' if new_resource.ram

      ['rabbitmqctl stop_app', join_cmd, 'rabbitmqctl start_app'].each do |cmd|
        cmd = Mixlib::ShellOut.new(cmd, :environment => {'HOME' => '/tmp'})
        cmd.run_command
        cmd.error!
      end

      Chef::Log.info('successfully joined with cluster_node: ' + new_resource.cluster_node)
      record_cluster_node(new_resource.cluster_node)
    end
  end
end
