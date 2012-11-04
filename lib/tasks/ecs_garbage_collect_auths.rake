namespace :ecs do
  desc "Deletes outtimed authorization tokens (needs ps system command)."
  task :gc_sys_auths => :environment  do
    gc_sys_auths_pid= "#{Rails.root}/tmp/pids/gc_sys_auths.pid"
    if File.exists?(gc_sys_auths_pid)
      pid= ""
      gc_sys_auths_is_running= false
      File.open(gc_sys_auths_pid,"r") do |f|
        pid= f.readline.strip
      end
      p= open("|ps ax")
      p.each_line do |line|
        if line.index(pid)
          gc_sys_auths_is_running= true
          break
        end
      end
      p.close
      if gc_sys_auths_is_running
        RAILS_DEFAULT_LOGGER.info "GC: there seems to be already running a ecs:gc_sys_auths process (#{gc_sys_auths_pid}). Aborting."
        puts "GC: there seems to be already running a ecs:gc_sys_auths process (#{gc_sys_auths_pid}). Aborting."
        raise 'gc_sys_auths.pid file exists!'
      end
    end
    File.open(gc_sys_auths_pid,"w") do |f|
      f.puts "#{Process.pid}"
    end
    begin
      sleep 5
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
    ensure
      begin
        #File.delete(gc_sys_auths_pid)
      rescue
      end
    end
  end
end
