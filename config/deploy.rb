# config valid only for current version of Capistrano
# lock '3.7.2'

set :repo_url, "https://github.com/pulibrary/bibdata.git"

# Default branch is :main
set :branch, ENV['BRANCH'] || 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, -> { "/opt/#{fetch(:application)}" }
set :repo_path, ->{ "/opt/#{fetch(:application)}/repo" }
# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

set :ssh_options, { forward_agent: true }

set :passenger_restart_with_touch, true

# Default value for :pty is false
# set :pty, true

# Default value for linked_dirs is []
set :linked_dirs, %w{
  tmp/pids
  tmp/cache
  tmp/figgy_ark_cache
  tmp/sockets
  vendor/bundle
  public/system
  log
  campus_access
}


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :whenever_roles, ->{ [:cron, :cron_staging, :cron_production, :hr_cron] }

namespace :sidekiq do
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "bibdata-workers", :restart
    end
  end
end

namespace :sqs_poller do
  task :restart do
    on roles(:poller) do
      execute :sudo, :service, "bibdata-sqs-poller", :restart
    end
  end
end

namespace :seeder do
  task :load_dump_types do
    on roles(:worker) do
      within release_path do
        execute :rake, 'marc_liberation:load_dump_types'
      end
    end
  end
end

after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'
after 'deploy:restart', 'sqs_poller:restart'
after 'sidekiq:restart', 'seeder:load_dump_types'

namespace :deploy do
  desc "Check that we can access everything"
  task :check_write_permissions do
    on roles(:all) do |host|
      if test("[ -w #{fetch(:deploy_to)} ]")
        info "#{fetch(:deploy_to)} is writable on #{host}"
      else
        error "#{fetch(:deploy_to)} is not writable on #{host}"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'
end
