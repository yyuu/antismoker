#!/usr/bin/env ruby

require "antismoker"

desc("Run smoke test.")
task(:antismoker) do
  Rake::Task["antismoker:invoke"].invoke
end

namespace(:antismoker) do
  desc("Run smoke test.")
  task(:invoke) do
    env = defined?(RAILS_ENV) ? RAILS_ENV : ENV.fetch("RAILS_ENV", "development")
    smoketests = AntiSmoker.load("config/antismoker.yml", :env => env)
    results = AntiSmoker.run(smoketests)
    abort unless results.all?
  end
end

# vim:set ft=ruby ts=2 sw=2 :
