#!/usr/bin/env ruby

require "antismoker/tests"
require "net/http"
require "uri"
require "antismoker/tests/http.rb"

module AntiSmoker
  class HttpsTest < HttpTest
    def uri
      URI::HTTPS.build(:host => host, :port => port, :path => path)
    end

    def fetch(uri, options={})
      limit = options.fetch(:limit, 10)
      method = options.fetch(:method, "GET")
      raise(ArgumentError.new("HTTP redirect too deep")) if limit <= 0

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      case method
      when /^post$/i
        response = http.post(uri.request_uri.to_s, data)
      else
        response = http.get(uri.request_uri.to_s)
      end
      if Net::HTTPRedirection === response
        location = URI.parse(response["location"])
        new_uri = (location.absolute?) ? location : uri.merge(location)
        fetch(new_uri, :limit => limit-1)
      else
        response
      end
    end
  end
end
