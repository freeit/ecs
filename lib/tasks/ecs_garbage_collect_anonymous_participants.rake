namespace :ecs do
  desc "Delete outtimed anonymous participants."
  task :gc_anonymous_participants => :environment  do
    num= Participant.find(:all, :conditions => ["(anonymous = ?) AND (ttl < ?)", true, DateTime.now.utc]).length
    Participant.destroy_all(["(anonymous = ?) AND (ttl < ?)", true, DateTime.now.utc])
    txt= "gc_anonymous_participants: Number of deleted outtimed anonymous participants: #{num}"
    puts txt
    RAILS_DEFAULT_LOGGER.info txt
  end
end
