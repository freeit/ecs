namespace :ecs do
  desc "Delete outtimed subparticipants."
  task :gc_sub_participants => :environment  do
    ttl= 10.days.ago
    num= 0
    Participant.only_subparticipants.each do |p|
      if p.created_at <= ttl
        p.destroy
        num+=1
      end
    end
    txt= "Number of deleted subparticipants: #{num}"
    puts txt
    RAILS_DEFAULT_LOGGER.info txt
  end
end
