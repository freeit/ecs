namespace :vip do
  desc "Delete old solutions."
  task :gc_solutions => :environment  do
    ttl= 15.hours.ago
    i=0
    Message.for_resource("numlab", "solutions").for_not_removed.each do |msg|
      if msg.created_at < ttl
        m = Message.find(msg.id)
        m.destroy_as_sender
        i+=1
        txt= "gc_solutions: #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.info txt
        #puts txt
      end
    end
    txt= "gc_solutions: Deleted #{i} solutions."
    RAILS_DEFAULT_LOGGER.info txt
    puts txt
  end
end
