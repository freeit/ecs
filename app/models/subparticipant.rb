# Copyright (C) 2014 Heiko Bernloehr (FreeIT.de).
#
# This file is part of ECS.
#
# ECS is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# ECS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with ECS. If not, see <http://www.gnu.org/licenses/>.

class Subparticipant < ActiveRecord::Base

  TTL = 3600 # seconds, how long a subparticipant lives, after last
             # communication with ECS

  require 'securerandom'

  belongs_to  :parent,
              :class_name => "Participant",
              :foreign_key => "parent_id"

  belongs_to  :participant


  def self.generate(parent, json_data) 
    auth_id= Identity.randomized_authid
    data = process_json_data(parent, json_data)
    check_valid_communities(parent ,data[:community_ids])
    params = {
        "name" => "Subparticipant (\##{SecureRandom.hex}) from #{parent.name}",
        "identities_attributes" => {"0"=>{"name"=>"#{auth_id}", "description"=>"Randomized authid"}},
        "community_ids" => data[:community_ids],
        "description" => "",
        "dns" => "N/A",
        "organization_id" => parent.organization.id,
        "email" => parent.email,
        "ttl" => nil,
        "anonymous" => false,
        "community_selfrouting" => data[:community_selfrouting],
        "events_" => data[:events],
        "subparticipant_attributes" => { :realm => data[:realm] } 
    }
    participant = Participant.new(params)
    participant.save!
    subp= participant.subparticipant
    subp.parent= parent
    subp.save!
    participant.name= "Subparticipant (id:#{subp.id})"
    participant.description= "Created from \"#{parent.name}\" (pid:#{parent.id})"
    participant.save!
    subp
  end

  def update__(parent, json_data, subparticipant)
    participant= subparticipant.participant
    auth_id= "dummy"
    data= process_json_data(parent, json_data)
    check_valid_communities(parent, data[:community_ids])
    params = {
        "community_selfrouting" => data[:community_selfrouting],
        "community_ids" => data[:community_ids],
        "events_" => data[:events],
        "subparticipant_attributes" => { :id => self.id.to_s, :realm => data[:realm] }
    }
    participant.update_attributes(params)
  end

private

  def process_json_data(sender, json_data)
    Subparticipant::process_json_data(sender, json_data)
  end
    
  def self.process_json_data(sender, json_data)
    json_data= {} unless json_data.class == Hash
    realm= json_data["realm"] ||= nil
    community_selfrouting= json_data["community_selfrouting"] || false
    events= json_data["events"] ||= false
    if json_data["communities"]
      community_ids= json_data["communities"].map do |comm|
        case 
          when comm.class == Fixnum
            if Community.find_by_id(comm)
              comm
            else
              raise Ecs::InvalidMessageException, comm.to_s
            end
          when comm.class == String
            if (c= Community.find_by_name(comm))
              c.id
            else
              raise Ecs::InvalidMessageException, comm.to_s
            end
          else
            nil
        end
      end
    end
    community_ids ||= []
    community_ids.compact!
    { :realm => realm, :community_selfrouting => community_selfrouting, :events => events,
      :community_ids => community_ids }
  rescue Ecs::InvalidMessageException
    errortext= <<-END
You provided at least one unknown community for a subparticipant creation.
Following community is unknown (either a cid or a community name): #{$!}
    END
    raise Ecs::InvalidMessageException, errortext
  end

  def self.check_valid_communities(parent, community_ids)
    if community_ids.blank?
      logger.debug "Subparticipant#check_valid_communities: empty community_ids"
      return
    end
    parent_community_ids= parent.communities.map{|c| c.id}
    logger.debug "Subparticipant#check_valid_communities: parent community ids = [#{parent_community_ids.join(', ')}]"
    logger.debug "Subparticipant#check_valid_communities: subparticipant community ids = [#{community_ids.join(', ')}]"
    logger.debug "Subparticipant#check_valid_communities: Difference between subparticipant community ids and parent community ids = [#{(community_ids - parent_community_ids).join(', ')}]"
    unless (community_ids - parent_community_ids).blank?
      errortext= <<-END
The subparticipant's communities must be a subset of its parent.
Following communities are not allowed: #{(community_ids - parent_community_ids).map{|cid|Community.find(cid).name}.join(', ')}
      END
      raise Ecs::InvalidMessageException, errortext
    end
  end
    
end
