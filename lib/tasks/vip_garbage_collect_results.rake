namespace :vip do
  desc "Delete old results."
  task :gc_results => :environment  do
    # ttl= 20*60 # 20 minutes
    ttl= 1.month
    timenow= Time.now
    i=0
    Message.for_resource("numlab", "results").each do |msg|
      if msg.created_at < (timenow - ttl)
        i+=1
        msg.destroy_as_sender
        txt= "Service: garbage collect result: #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.info txt
        #puts txt
      end
    end
    puts "\nDeleted #{i} results."
  end
end
