namespace :vip do
  desc "Delete old results."
  task :gc_results => :environment  do
    ttl= 15.hours.ago
    i=0
    Message.for_resource("numlab", "results").each do |msg|
      begin
        if msg.created_at < ttl
          m = Message.find(msg.id)
          m.destroy_as_sender
          i+=1
          txt= "gc_results: #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
          RAILS_DEFAULT_LOGGER.info txt
          #puts txt
        end
      end
    end
    txt= "gc_results: Deleted #{i} results."
    RAILS_DEFAULT_LOGGER.info txt
    puts txt
  end
end
