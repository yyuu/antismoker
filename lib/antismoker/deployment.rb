#!/usr/bin/env ruby

module AntiSmoker
  class Deployment
    def self.define_task(context, task_method = :task, opts = {})
      if defined?(Capistrano) && context.is_a?(Capistrano::Configuration)
        context_name = "capistrano"
        role_default = "{:except => {:no_release => true}}"
        error_type = ::Capistrano::CommandError
      else
        context_name = "vlad"
        role_default = "[:app]"
        error_type = ::Rake::CommandFailedError
      end

      roles = context.fetch(:antismoker_roles, false)
      opts[:roles] = roles if roles

      context.send :namespace, :antismoker do
        send :desc, "Run smoke test."
        send task_method, :invoke, opts do
          rake_cmd = context.fetch(:rake, "rake")
          antismoker_task = context.fetch(:antismoker_task, "antismoker:invoke")
          rails_env = context.fetch(:rails_env, "production")
          app_path = context.fetch(:latest_release)
          if app_path.to_s.empty?
            raise error_type.new("Cannot detect current release path - make sure you have deployed at least once.")
          end
          args = []
          args += context.fetch(:antismoker_flags, [])
          args << "RAILS_ENV=#{rails_env}"

          begin
            run "cd #{app_path} && #{rake_cmd} #{args.join(' ')} #{antismoker_task}"
            antismoker_success
          rescue
            antismoker_failure
          ensure
            finalize_antismoker
          end
        end

        send task_method, :antismoker_success, opts do
          logger.info("It works!")
        end

        send task_method, :antismoker_failure, opts do
          if context.fetch(:antismoker_use_rollback, false)
            logger.info("Rolling back application.")
            rollback_task = context.fetch(:antismoker_rollback_task, "deploy:rollback")
            find_and_execute_task(rollback_task)
          end
        end

        send task_method, :finalize_antismoker, opts do
          # nop
        end
      end
    end
  end
end

# vim:set ft=ruby sw=2 ts=2 :
