namespace :vip do
  desc "Delete old evaluations."
  task :gc_evaluations => :environment  do
    ttl= 15.hours.ago
    i=0
    Message.for_resource("numlab", "evaluations").for_not_removed.each do |msg|
      begin
        if msg.created_at < ttl
          m = Message.find(msg.id)
          m.destroy_as_sender
          i+=1
          txt= "gc_evaluations: #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
          RAILS_DEFAULT_LOGGER.info txt
          puts txt
        end
      end
    end
    txt= "gc_evaluations: Deleted #{i} evaluations."
    RAILS_DEFAULT_LOGGER.info txt
    puts txt
  end
end
