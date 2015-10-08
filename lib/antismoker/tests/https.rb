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
  end
end

