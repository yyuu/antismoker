#!/usr/bin/env ruby

require "socket"
require "yaml"

module AntiSmoker
  DEFAULT_PROTOCOL_NAME = "__default__"
  DEFAULT_PROTOCOL_OPTIONS = {
    :count => 3, # test retry count
    :delay => 0.0, # delay for first test in seconds.
    :period => 3.0, # retry interval between each tests.
    :timeout => 5.0, # test timeout
  }

  def load(file, options={})
    env = options.fetch(:env, "development")
    defs = YAML.load(File.read(file))
    abort("No such environment was defined in #{file}: #{env}") unless defs.has_key?(env)

    smoketests = []
    defs[env].each do |host, smoke_spec|
      default_options = smoke_spec.delete(DEFAULT_PROTOCOL_NAME)
      DEFAULT_PROTOCOL_OPTIONS.update(default_options) if default_options

      smoke_spec.each do |protocol, options|
        begin
          require "antismoker/tests/#{protocol}"
        rescue LoadError => error
          abort("Could not load smoke test for #{protocol}: #{error}")
        end

        begin
          name = protocol.scan(/\w+/).map { |w| w.capitalize }.join
          klass = AntiSmoker.const_get("#{name}Test")
        rescue NameError => error
          abort("[BUG] Broken smoke test for #{protocol}: #{error}")
        end

        if options.is_a?(Hash)
          options = DEFAULT_PROTOCOL_OPTIONS.merge(options)
        else
          options = DEFAULT_PROTOCOL_OPTIONS.merge(:port => options)
        end
        begin
          options[:port] = Socket.getservbyname(protocol) unless options.has_key?(:port)
        rescue SocketError => error
          abort("Could not resolve well-known port for #{protocol}: #{error}")
        end
        ports = [ options.delete(:port) ].flatten
        smoketests += ports.map { |port| klass.new(host, port, options) }
      end
    end

    smoketests
  end
  module_function :load
end

# vim:set ft=ruby sw=2 ts=2 :
