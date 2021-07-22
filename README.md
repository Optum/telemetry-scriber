# Telemetry::Scriber
The Telemetry::Scriber gem is used in subscribing to a RabbitMQ broker, consuming line protocol messages and then 
posting them to InfluxDB. This is just a single component of the Telemetry stack and should be used in combination
with Telemetry::Attributes, Telemetry::Conflux, etc

When this application starts, it will take care of connecting to the queue tier, creating
the queue(s) and making sure they are configured correctly  

This gem is extremely configurable. Here are some of the standard config options
```ruby
{
  queue_defaults: {
    queue_prefix: 'influxdb.',
    queue_name:   'system_hostname',
    max_in_memory_bytes: 1_048_576_000,
    max_in_memory_length: 2_000,
    dead_letter_ex: 'telemetry.overflow',
    overflow: 'drop-head',
    delivery_limit: 2,
    max_length_bytes: 10_073_741_824,
    max_length: 1000,
    x_expires: 3_600_000
  }
}
```

Writer Defaults
```ruby
{
  host: 'localhost',
  port: 8086,
  username: nil,
  password: nil,
  pool_size: 30,
  write_timeout: 10,
  open_timeout: 10,
  max_retries: 10,
  retry: false
}
```