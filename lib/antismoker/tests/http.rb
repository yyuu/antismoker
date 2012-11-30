#!/usr/bin/env ruby

require "antismoker/tests"
require "net/http"
require "uri"

module AntiSmoker
  class HttpTest < AbstractSmokeTest
    def initialize(host, port, options={})
      super
      @data = options.fetch(:data, {})
      @method = options.fetch(:method, "GET")
      @path = options.fetch(:path, "/")
      @ok = options.fetch(:ok, 200)
    end
    attr_reader :data
    attr_reader :method
    attr_reader :path

    def run_once(options={})
      response = fetch(uri, :method => method)
      logger.debug("HTTP response: #{self} => #{response.code} (#{response.body.length} bytes)")
      response_ok(response)
    end

    def fetch(uri, options={})
      limit = options.fetch(:limit, 10)
      method = options.fetch(:method, "GET")
      raise(ArgumentError.new("HTTP redirect too deep")) if limit <= 0
      case method
      when /^post$/i
        response = Net::HTTP.post_form(uri, data)
      else
        response = Net::HTTP.get_response(uri)
      end
      if Net::HTTPRedirection === response
        location = URI.parse(response["location"])
        new_uri = (location.absolute?) ? location : uri.merge(location)
        fetch(new_uri, :limit => limit-1)
      else
        response
      end
    end

    def response_ok(response)
      code = response.code.to_i
      [ @ok ].flatten.compact.map { |x| x === code }.any?
    end

    def uri
      URI::HTTP.build(:host => host, :port => port, :path => path)
    end

    def to_s
      "#{method} #{uri}"
    end
  end
end

# vim:set ft=ruby sw=2 ts=2 :
