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

  require 'securerandom'

  belongs_to  :parent,
              :class_name => "Participant",
              :foreign_key => "parent_id"

  belongs_to  :participant


  def self.generate(sender, json_data) 
    auth_id= Identity.randomized_authid
    data = process_json_data(sender, json_data)
    params = {
        "name" => "Subparticipant (\##{SecureRandom.hex}) from #{sender.name}",
        "identities_attributes" => {"0"=>{"name"=>"#{auth_id}", "description"=>"Randomized authid"}},
        "community_ids" => data[:community_ids],
        "description" => "",
        "dns" => "N/A",
        "organization_id" => sender.organization.id,
        "email" => sender.email,
        "ttl" => nil,
        "anonymous" => false,
        "community_selfrouting" => data[:community_selfrouting],
        "events_" => data[:events],
        "subparticipant_attributes" => { :realm => data[:realm] } 
    }
    participant = Participant.new(params)
    participant.save!
    subp= participant.subparticipant
    subp.parent= sender
    subp.save!
    participant.name= "Subparticipant (id:#{subp.id})"
    participant.description= "Created from \"#{sender.name}\" (pid:#{sender.id})"
    participant.save!
    subp
  end

  def update__(sender, json_data, subparticipant)
    participant= subparticipant.participant
    auth_id= "dummy"
    data= process_json_data(sender, json_data)
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
    realm= json_data["realm"] ||= nil
    community_selfrouting= json_data["community_selfrouting"] || false
    events= json_data["events"] ||= false
    if json_data["communities"]
      community_ids= json_data["communities"].map do |comm|
        erg= case 
          when comm.class == Fixnum
            comm.to_s
          when comm.class == String
            (c= Community.find_by_name(comm)) ? c.id.to_s : nil
          else
            nil
        end
      end
    end
    community_ids ||= []
    community_ids.compact!
    { :realm => realm, :community_selfrouting => community_selfrouting, :events => events,
      :community_ids => community_ids }
  end
    
end
