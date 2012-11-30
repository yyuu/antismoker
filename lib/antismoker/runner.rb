#!/usr/bin/env ruby

require "thread"

module AntiSmoker
  def run(smoketests=[], options={})
    results = smoketests.map { |smoketest|
      run_single(smoketest, options)
    }
  rescue Interrupt
    abort("Interrupted")
  end
  module_function :run

  def run_single(smoketest, options={})
    begin
      smoketest.run(options)
    rescue => error
      false
    end
  end
  module_function :run_single
end

# vim:set ft=ruby sw=2 ts=2 :
