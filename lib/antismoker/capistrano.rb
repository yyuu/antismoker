#!/usr/bin/env ruby

require "antismoker/deployment"

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy", "antismoker:invoke"
  after "deploy:cold", "antismoker:invoke"
  AntiSmoker::Deployment.define_task(self, :task, :except => { :no_release => true })
end

# vim:set ft=ruby sw=2 ts=2 :
