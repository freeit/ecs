namespace :vip do
  desc "Delete old exercises."
  task :gc_exercises => :environment  do
    # ttl= 20*60 # 20 minutes
    ttl= 30*24*3600 # 9999 years
    Message.for_resource("numlab", "exercises").sort{|x,y| x.created_at <=> y.created_at}.each do |msg|
      begin
        body= JSON.parse(msg.body)
        post_time= JSON.parse(msg.body)['Exercise']['postTime']
        diff_time= Time::now.utc - Time::utc(*ParseDate::parsedate(post_time)) - ttl
        if diff_time >= 0
          Message::destroy_msg(msg)
          txt= "Filter: delete message (#{Time::utc(*ParseDate::parsedate(post_time))}): #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
          RAILS_DEFAULT_LOGGER.info txt
          puts txt
        end
      rescue JSON::ParserError, Exception
        txt= "Filter Exception: "+$!.class.to_s+": #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.error txt
        puts txt
      end
    end
  end
end
