class Auth < ActiveRecord::Base
  belongs_to :message 

  #named_scope :hash, lambda {|hash| {
  #  :joins => {:membership_messages => {:membership => :participant}},
  #  :order => "id ASC",
  #  :conditions => {:participants => {:id => participant.id}}}}


  def test_validation_window
    b = JSON.parse(message.body)
    sov = Time.parse(b["sov"]) 
    eov = Time.parse(b["eov"]) 
    if sov > Time.now or eov < Time.now
      false
    else
      true
    end
  end

  # garbage collect outtimed authorization tokens
  def self.gc_outtimed
    gc_sys_auths_lock= "#{Rails.root}/tmp/gc_sys_auths.lock"
    if File.exists?(gc_sys_auths_lock)
      logtext= "GC: there seems to be already running a ecs:gc_sys_auths process (#{gc_sys_auths_lock}). Aborting."
      logger.info logtext
      puts logtext unless Rails.env.test?
    else
      begin
        File.open(gc_sys_auths_lock,"w") do |f|
          f.puts "#{Process.pid}"
        end
        logtext= "GC: Searching for outtimed auths ..."
        logger.info logtext
        puts logtext unless Rails.env.test?
        Auth.all.each do |auth|
          if ! auth.test_validation_window
            auth.message.destroy_as_sender
            logtext= "GC: garbage collect auths token: #{auth.one_touch_hash}"
            logger.info logtext
            puts logtext unless Rails.env.test?
          end
        end
        logtext= "GC: Searching for outtimed auths done."
        logger.info logtext
        puts logtext unless Rails.env.test?
      ensure
        begin
          File.delete(gc_sys_auths_lock)
        rescue
        end
      end
    end
  end

end
