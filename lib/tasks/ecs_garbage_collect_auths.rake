namespace :ecs do
  desc "Deletes outtimed authorization tokens."
  task :gc_sys_auths => :environment  do
    ps= `ps ax | grep -v 'grep' | grep -v "^[ \t]*#{Process.pid}" | grep 'rake ecs:gc_sys_auths'`
    if !ps.empty?
      RAILS_DEFAULT_LOGGER.info "GC: there is already running a ecs:gc_sys_auths process. Aborting."
      puts "GC: There is already running a ecs:gc_sys_auths process. Aborting."
      exit 1
    end
    RAILS_DEFAULT_LOGGER.info "GC: Searching for outtimed auths ..."
    puts "GC: Searching for outtimed auths ..."
    Message.all.each do |m|
      if m.auth
        if ! m.test_auths_validation_window
          m.destroy_as_sender
          RAILS_DEFAULT_LOGGER.info "GC: garbage collect auths token with id=#{m.id}."
          puts "delete outtimed authorization token with id=#{m.id}"
        end
      end
    end
    RAILS_DEFAULT_LOGGER.info "GC: Searching for outtimed auths done."
    puts "GC: Searching for outtimed auths done."
  end
end
