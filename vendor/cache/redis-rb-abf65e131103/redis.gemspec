# -*- encoding: utf-8 -*-
# stub: redis 3.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "redis"
  s.version = "3.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ezra Zygmuntowicz", "Taylor Weibley", "Matthew Clark", "Brian McKinney", "Salvatore Sanfilippo", "Luca Guidi", "Michel Martens", "Damian Janowski", "Pieter Noordhuis"]
  s.date = "2014-04-20"
  s.description = "    A Ruby client that tries to match Redis' API one-to-one, while still\n    providing an idiomatic interface. It features thread-safety,\n    client-side sharding, pipelining, and an obsession for performance.\n"
  s.email = ["redis-db@googlegroups.com"]
  s.files = [".gitignore", ".order", ".travis.yml", ".travis/Gemfile", ".yardopts", "CHANGELOG.md", "LICENSE", "README.md", "Rakefile", "benchmarking/logging.rb", "benchmarking/pipeline.rb", "benchmarking/speed.rb", "benchmarking/suite.rb", "benchmarking/worker.rb", "examples/basic.rb", "examples/dist_redis.rb", "examples/incr-decr.rb", "examples/list.rb", "examples/pubsub.rb", "examples/sets.rb", "examples/unicorn/config.ru", "examples/unicorn/unicorn.rb", "lib/redis.rb", "lib/redis/client.rb", "lib/redis/connection.rb", "lib/redis/connection/command_helper.rb", "lib/redis/connection/hiredis.rb", "lib/redis/connection/registry.rb", "lib/redis/connection/ruby.rb", "lib/redis/connection/synchrony.rb", "lib/redis/distributed.rb", "lib/redis/errors.rb", "lib/redis/hash_ring.rb", "lib/redis/pipeline.rb", "lib/redis/subscribe.rb", "lib/redis/version.rb", "redis.gemspec", "test/blocking_commands_test.rb", "test/command_map_test.rb", "test/commands_on_hashes_test.rb", "test/commands_on_lists_test.rb", "test/commands_on_sets_test.rb", "test/commands_on_sorted_sets_test.rb", "test/commands_on_strings_test.rb", "test/commands_on_value_types_test.rb", "test/connection_handling_test.rb", "test/db/.gitkeep", "test/distributed_blocking_commands_test.rb", "test/distributed_commands_on_hashes_test.rb", "test/distributed_commands_on_lists_test.rb", "test/distributed_commands_on_sets_test.rb", "test/distributed_commands_on_sorted_sets_test.rb", "test/distributed_commands_on_strings_test.rb", "test/distributed_commands_on_value_types_test.rb", "test/distributed_commands_requiring_clustering_test.rb", "test/distributed_connection_handling_test.rb", "test/distributed_internals_test.rb", "test/distributed_key_tags_test.rb", "test/distributed_persistence_control_commands_test.rb", "test/distributed_publish_subscribe_test.rb", "test/distributed_remote_server_control_commands_test.rb", "test/distributed_scripting_test.rb", "test/distributed_sorting_test.rb", "test/distributed_test.rb", "test/distributed_transactions_test.rb", "test/encoding_test.rb", "test/error_replies_test.rb", "test/helper.rb", "test/helper_test.rb", "test/internals_test.rb", "test/lint/blocking_commands.rb", "test/lint/hashes.rb", "test/lint/lists.rb", "test/lint/sets.rb", "test/lint/sorted_sets.rb", "test/lint/strings.rb", "test/lint/value_types.rb", "test/persistence_control_commands_test.rb", "test/pipelining_commands_test.rb", "test/publish_subscribe_test.rb", "test/remote_server_control_commands_test.rb", "test/scanning_test.rb", "test/scripting_test.rb", "test/sorting_test.rb", "test/support/connection/hiredis.rb", "test/support/connection/ruby.rb", "test/support/connection/synchrony.rb", "test/support/redis_mock.rb", "test/support/wire/synchrony.rb", "test/support/wire/thread.rb", "test/synchrony_driver.rb", "test/test.conf", "test/thread_safety_test.rb", "test/transactions_test.rb", "test/unknown_commands_test.rb", "test/url_param_test.rb"]
  s.homepage = "https://github.com/redis/redis-rb"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "A Ruby client library for Redis"
  s.test_files = ["test/blocking_commands_test.rb", "test/command_map_test.rb", "test/commands_on_hashes_test.rb", "test/commands_on_lists_test.rb", "test/commands_on_sets_test.rb", "test/commands_on_sorted_sets_test.rb", "test/commands_on_strings_test.rb", "test/commands_on_value_types_test.rb", "test/connection_handling_test.rb", "test/db/.gitkeep", "test/distributed_blocking_commands_test.rb", "test/distributed_commands_on_hashes_test.rb", "test/distributed_commands_on_lists_test.rb", "test/distributed_commands_on_sets_test.rb", "test/distributed_commands_on_sorted_sets_test.rb", "test/distributed_commands_on_strings_test.rb", "test/distributed_commands_on_value_types_test.rb", "test/distributed_commands_requiring_clustering_test.rb", "test/distributed_connection_handling_test.rb", "test/distributed_internals_test.rb", "test/distributed_key_tags_test.rb", "test/distributed_persistence_control_commands_test.rb", "test/distributed_publish_subscribe_test.rb", "test/distributed_remote_server_control_commands_test.rb", "test/distributed_scripting_test.rb", "test/distributed_sorting_test.rb", "test/distributed_test.rb", "test/distributed_transactions_test.rb", "test/encoding_test.rb", "test/error_replies_test.rb", "test/helper.rb", "test/helper_test.rb", "test/internals_test.rb", "test/lint/blocking_commands.rb", "test/lint/hashes.rb", "test/lint/lists.rb", "test/lint/sets.rb", "test/lint/sorted_sets.rb", "test/lint/strings.rb", "test/lint/value_types.rb", "test/persistence_control_commands_test.rb", "test/pipelining_commands_test.rb", "test/publish_subscribe_test.rb", "test/remote_server_control_commands_test.rb", "test/scanning_test.rb", "test/scripting_test.rb", "test/sorting_test.rb", "test/support/connection/hiredis.rb", "test/support/connection/ruby.rb", "test/support/connection/synchrony.rb", "test/support/redis_mock.rb", "test/support/wire/synchrony.rb", "test/support/wire/thread.rb", "test/synchrony_driver.rb", "test/test.conf", "test/thread_safety_test.rb", "test/transactions_test.rb", "test/unknown_commands_test.rb", "test/url_param_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
