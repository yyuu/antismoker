set :application, "antismoker"
set :repository, File.expand_path("../..", File.dirname(__FILE__))
set :deploy_to do
  File.join("/home", user, application)
end
set :deploy_via, :copy
set :scm, :none
set :use_sudo, false
set :user, "vagrant"
set :password, "vagrant"
set :ssh_options, {
  :auth_methods => %w(publickey password),
  :keys => File.join(ENV["HOME"], ".vagrant.d", "insecure_private_key"),
  :user_known_hosts_file => "/dev/null"
}

## rbenv ##
require "capistrano-rbenv"
set(:rbenv_ruby_version, "1.9.3-p392")
set(:rbenv_install_bundler, true)

role :web, "192.168.33.10"
role :app, "192.168.33.10"
role :db,  "192.168.33.10", :primary => true

$LOAD_PATH.push(File.expand_path("../../lib", File.dirname(__FILE__)))
require "antismoker/capistrano"
require "benchmark"
set(:rails_env, "production")
set(:antismoker_http_count, 7)
set(:antismoker_http_delay, 4)
set(:antismoker_http_period, 2)
set(:antismoker_http_timeout, 1)

def setup_service!
  case platform_family
  when :debian
    platform.packages.install("apache2")
  when :redhat
    platform.packages.install("httpd")
    run("#{sudo} touch /var/www/html/index.html")
    run("#{sudo} service httpd restart || #{sudo} service httpd start")
  else
  end
end

def reset_all!()
  variables.each_key do |key|
    reset!(key)
  end
end

def assert_equals(x, y)
  raise("assert_equals(#{x.inspect}, #{y.inspect}) failed.") if x != y
end

def assert_not_equals(x, y)
  raise("assert_not_equals(#{x.inspect}, #{y.inspect}) failed.") if x == y
end

def assert_in_time(min, max, &block)
  s = Benchmark.realtime do
    yield
  end
  raise("assert_in_time(#{min}, #{max}) failed. (s=#{s})") if min > s or s > max
end

def assert_aborts(&block)
  begin
    yield
  rescue SystemExit
    aborted = true
  ensure
    raise("assert_aborts failed.") unless aborted
  end
end

def assert_aborts_in_time(min, max, &block)
  assert_in_time(min, max) do
    assert_aborts(&block)
  end
end

def configure(s, options={})
  s = s.to_yaml unless s.is_a?(String)
  top.run("mkdir -p #{File.join(release_path, "config").dump}", options)
  top.put(s, File.join(release_path, "config/antismoker.yml"), options)
end

def antismoker_yml
  {
    fetch(:rails_env, "production") => {
      "127.0.0.1" => {
        "http" => {
          :port => fetch(:antismoker_http_port, 80),
          :path => fetch(:antismoker_http_path, "/"),
          :count => fetch(:antismoker_http_count, 3),
          :delay => fetch(:antismoker_http_delay, 0.0),
          :period => fetch(:antismoker_http_period, 3.0),
          :timeout => fetch(:antismoker_http_timeout, 5.0),
        }
      }
    }
  }.to_yaml
end

on(:load) {
  run("rm -rf #{deploy_to.dump}")
}

task(:test_all) {
  find_and_execute_task("test_default")
  find_and_execute_task("test_rollback")
}

namespace(:test_default) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_default", "test_default:setup"
  after "test_default", "test_default:teardown"

  task(:setup) {
    setup_service!
    find_and_execute_task("deploy:setup")
    configure({rails_env => {}}) # an empty test
    find_and_execute_task("deploy")
  }

  task(:teardown) {
  }

  task(:test_success) {
    set(:antismoker_http_port, 80)
    set(:antismoker_http_path, "/")
    set(:antismoker_use_rollback, false)
    configure(antismoker_yml)
    min = antismoker_http_delay
    max = antismoker_http_delay + antismoker_http_timeout
    assert_in_time(min, max) do
      find_and_execute_task("antismoker:invoke")
    end
  }

  task(:test_failure_with_invalid_port) {
    set(:antismoker_http_port, 8080)
    set(:antismoker_http_path, "/")
    set(:antismoker_use_rollback, false)
    configure(antismoker_yml)
    min = antismoker_http_delay + antismoker_http_count * antismoker_http_period
    max = antismoker_http_delay + antismoker_http_count * (antismoker_http_period + antismoker_http_timeout)
    assert_aborts_in_time(min, max) do
      find_and_execute_task("antismoker:invoke")
    end
  }

  task(:test_failure_with_invalid_path) {
    set(:antismoker_http_port, 80)
    set(:antismoker_http_path, "/MUST_NOT_EXIST")
    configure(antismoker_yml)
    min = antismoker_http_delay + antismoker_http_count * antismoker_http_period
    max = antismoker_http_delay + antismoker_http_count * (antismoker_http_period + antismoker_http_timeout)
    assert_aborts_in_time(min, max) do
      find_and_execute_task("antismoker:invoke")
    end
  }
}

namespace(:test_rollback) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_rollback", "test_rollback:setup"
  after "test_rollback", "test_rollback:teardown"

  task(:setup) {
    setup_service!
    find_and_execute_task("deploy:setup")
  }

  task(:teardown) {
  }

  task(:test_success) {
    original_release = fetch(:current_release)
    reset_all!
    set(:antismoker_http_port, 80)
    set(:antismoker_http_path, "/")
    set(:antismoker_use_rollback, true)
    configure(antismoker_yml)
    find_and_execute_task("deploy")
    reset_all!
    assert_not_equals(current_release, original_release)
  }

  task(:test_failure) {
    original_release = fetch(:current_release)
    reset_all!
    set(:antismoker_http_port, 8080)
    set(:antismoker_http_path, "/")
    set(:antismoker_use_rollback, true)
    configure(antismoker_yml)
    assert_aborts do
      find_and_execute_task("deploy")
    end
    reset_all!
    assert_equals(current_release, original_release)
  }
}

# vim:set ft=ruby sw=2 ts=2 :
