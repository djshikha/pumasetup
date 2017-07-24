

server '35.154.86.56', port: 22, roles: [:web, :app, :db], primary: true

set :repo_url,        'git@github.com:djshikha/pumasetup.git'
set :application,     'pumasetup'
set :user,            'ubuntu'
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
#set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :deploy_to,       "/var/www/pumasetup"
set :puma_bind,       "unix:///var/www/pumasetup/shared/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "/var/www/pumasetup/shared/tmp/pids/puma.state"
set :puma_pid,        "/var/www/pumasetup/shared/tmp/pids/puma.pid"
set :puma_access_log, "/var/www/pumasetup/shared/log/puma.error.log"
set :puma_error_log,  "/var/www/pumasetup/shared/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: "~/Downloads/djpuma.pem" }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

## Defaults:
# set :scm,           :git
# set :branch,        :master
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

## Linked Files & Directories (Default None):
# set :linked_files, %w{config/database.yml}
# set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir /var/www/pumasetup/shared/tmp/sockets -p"
      execute "mkdir /var/www/pumasetup/shared/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma