namespace :vip do
  desc "Delete old results."
  task :gc_results => :environment  do
    ttl= 2.days.ago
    i=0
    Message.for_resource("numlab", "results").each do |msg|
      begin
        if msg.created_at < ttl
          i+=1
          msg.destroy_as_sender
          txt= "gc_results: #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
          RAILS_DEFAULT_LOGGER.info txt
          #puts txt
        end
      rescue ActiveRecord::ReadOnlyRecord
        txt= "gc_results:Exception: "+$!.class.to_s+": Delete readonly results #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.info txt
        puts txt
        tmp_msg=Message.find(msg.id)
        tmp_msg.destroy_as_sender
        i+=1
      end
    end
    txt= "gc_results: Deleted #{i} results."
    RAILS_DEFAULT_LOGGER.info txt
    puts txt
  end
end
