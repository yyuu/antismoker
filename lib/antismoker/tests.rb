#!/usr/bin/env ruby

require "logger"
require "timeout"

module AntiSmoker
  class AbstractSmokeTest
    def initialize(host, port, options={})
      @host = host
      @port = port
      @options = options

      @delay = options[:delay]
      @count = options[:count]
      @period = options[:period]
      @timeout = options[:timeout]

      @logger = Logger.new(STDERR)
      @logger.level = Logger.const_get(options.fetch(:log, :info).to_s.upcase)
    end
    attr_reader :host
    attr_reader :port
    attr_reader :options

    attr_reader :delay
    attr_reader :count
    attr_reader :period
    attr_reader :timeout

    attr_reader :logger

    def sleep_with_progress(n)
      deadline = Time.now + n
      while Time.now < deadline
        STDOUT.putc(?.)
        STDOUT.flush
        sleep(n / 3)
      end
    end

    def run(options={})
      STDOUT.write("smoke testing: #{self}: ")
      sleep_with_progress(delay)
      n = 0
      while n < count
        if run_once_with_timeout(options)
          STDOUT.puts(" [\e[1;32m OK \e[0m]")
          return true
        else
          STDOUT.putc(?!)
          sleep_with_progress(period)
          n += 1
        end
      end
      STDOUT.puts(" [\e[31m NG \e[0m]")
      return false
    end

    def run_once_with_timeout(options={})
      begin
        Timeout.timeout(timeout) {
          return run_once(options)
        }
      rescue Timeout::Error => error
        logger.warn("timed out: #{self}: #{error}")
      rescue => error
        logger.warn("unknown error: #{self}: #{error}")
      end
      false
    end

    def run_once(options={})
      raise("must be overridden")
    end
  end
end

# vim:set ft=ruby sw=2 ts=2 :
