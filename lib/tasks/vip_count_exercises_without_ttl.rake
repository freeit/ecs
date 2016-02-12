namespace :vip do
  desc "Count exercises without TTL attribute."
  task :count_no_ttl_exercises => :environment  do
    # ttl= 20*60 # 20 minutes
    ttl= 30*24*3600 # 9999 years
    nottl=0
    noexercise=0
    Message.for_resource("numlab", "exercises").sort{|x,y| x.created_at <=> y.created_at}.each do |msg|
      begin
        if JSON.parse(msg.body)['Exercise'].nil?
          noexercise+= 1 
        elsif JSON.parse(msg.body)['Exercise']['TTL'].nil?
          nottl+= 1
        end
      rescue JSON::ParserError, Exception
        txt= "Filter Exception: "+$!.class.to_s+": #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.error txt
        puts txt
      end
    end
    puts "Number of exercises: #{Message.for_resource("numlab", "exercises").length-noexercise}"
    puts "nottl: "+nottl.to_s
    puts "noexercise: "+noexercise.to_s
  end
end
