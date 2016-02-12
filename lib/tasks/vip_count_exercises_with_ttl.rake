namespace :vip do
  desc "Count exercises with TTL attribute."
  task :count_ttl_exercises => :environment  do
    ttl=[]
    noexercise=0
    Message.for_resource("numlab", "exercises").sort{|x,y| x.created_at <=> y.created_at}.each do |msg|
      begin
        if JSON.parse(msg.body)['Exercise'].nil?
          noexercise+= 1 
        elsif !JSON.parse(msg.body)['Exercise']['TTL'].nil?
          puts "Exercise (#{msg.id}) with TTL = " + JSON.parse(msg.body)['Exercise']['TTL'].to_s
          ttl << msg
        end
      rescue JSON::ParserError, Exception
        txt= "Filter Exception: "+$!.class.to_s+": #{msg.ressource.namespace}/#{msg.ressource.ressource}/#{msg.id.to_s}"
        RAILS_DEFAULT_LOGGER.error txt
        puts txt
      end
    end
    puts "ID's of exercises with ttl: " + ttl.map{|m| m.id}.join(', ')
    puts "noexercise: "+noexercise.to_s
    puts "Number of exercises: #{Message.for_resource("numlab", "exercises").length-noexercise}"
    puts "Number of exercises with ttl: " + ttl.length.to_s
  end
end
