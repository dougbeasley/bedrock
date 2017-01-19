{
  "data_dir" : "/opt/consul/data",
  "log_level" : "DEBUG",
  "server" : true,
  "bootstrap_expect" :  ${server_count},
  "start_join" : [${consul_join}]
}
