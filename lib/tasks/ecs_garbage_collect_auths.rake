namespace :ecs do
  desc "Delete outtimed authorization tokens."
  task :gc_sys_auths => :environment  do
    Auth.gc_outtimed
  end
end
