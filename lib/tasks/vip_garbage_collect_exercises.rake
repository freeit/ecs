namespace :vip do
  desc "Deletes old exercises."
  task :gc_exercises => :environment  do
    ttl = 15.hours.ago
    num=0
    Message.for_resource("numlab", "exercises").for_not_removed.sort{|x,y| x.created_at <=> y.created_at}.each do |msg|
      begin
        unless (JSON.parse(msg.body)['Exercise']['TTL'])
          txt = "gc_exercises: don't delete permanent exercise: #{msg.id}"
          puts txt
          RAILS_DEFAULT_LOGGER.info txt
          next
        end
        if msg.created_at < ttl
          m= Message.find(msg.id)
          m.destroy_as_sender
          num+=1
          txt= "gc_exercises: delete message (#{msg.created_at.httpdate}): #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
          RAILS_DEFAULT_LOGGER.info txt
          puts txt
        end
      rescue JSON::ParserError
        txt= "gc_exercises:Exception: "+$!.class.to_s+": #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.info txt
        #puts txt
        tmp_msg=Message.find(msg.id)
        tmp_msg.destroy_as_sender
        #num+=1
      rescue ActiveRecord::RecordNotFound 
        txt= "gc_exercises:Exception: "+$!.class.to_s+": #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.info txt
      end
    end
    txt= "gc_exercises: Number of deleted exercises: #{num}"
    puts txt
    RAILS_DEFAULT_LOGGER.info txt
  end
end
