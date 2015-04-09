actions :join_cluster
default_action :join_cluster

attribute :cluster_node, :kind_of => String, :name_attribute => true
attribute :ram,  :kind_of => [TrueClass, FalseClass], :default => false
