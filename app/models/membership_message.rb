# Copyright (C) 2007, 2008, 2009, 2010 Heiko Bernloehr (FreeIT.de).
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


class MembershipMessage < ActiveRecord::Base
  belongs_to  :membership
  belongs_to  :message

  # Populate the memberships_messages jointable if sender joins community with receiver
  def self.populate_jointable(record, x_ecs_receiver_memberships, x_ecs_receiver_communities, sender_participant)
    rec_mids = extract_x_ecs_receiver_memberships(x_ecs_receiver_memberships)
    rec_cids = extract_x_ecs_receiver_communities(x_ecs_receiver_communities)
    if rec_cids.blank? and rec_mids.blank?
      raise Ecs::MissingReceiverHeaderException, 
            "You must at least specify one of X-EcsReceiverMemberships or X-EcsReceiverCommunities header\r\n"
    end

    pop_succ = false
    memberships_for_sender_participant_id = Membership.for_participant_id(sender_participant.id)
    
    rec_mids.each do |rmid|
      # Test if sender joins same community as receiver
      if memberships_for_sender_participant_id.map{|m| m.community.id}.include?(Membership.find(rmid).community.id)
        Membership.find(rmid).messages << record unless MembershipMessage.find_by_membership_id_and_message_id(rmid, record.id)
        pop_succ = true
      end
    end

    rec_cids.each do |rcid|
      # Test if sender joins same community as receiver
      if memberships_for_sender_participant_id.map{|m| m.community.id}.include?(rcid)
        Community.find(rcid).memberships.each do |membership|
          if !MembershipMessage.find_by_membership_id_and_message_id(membership.id, record.id) and # relation already made
             (sender_participant.community_selfrouting or # address sender through community
               membership.participant.id != sender_participant.id) # address sender through community
              membership.messages << record
          end
        end
        pop_succ = true
      end
    end
          
    unless pop_succ
      raise Ecs::AuthorizationException,
            "You are not joining at least one of the community to which you are addressing.\r\n" +
            "or\r\n" +
            "You are not joining at least one of the same community as the receiving membership.\r\n"
    end
  rescue ActiveRecord::RecordNotFound
    raise Ecs::InvalidMessageException, 
          "Membership id in X-EcsReceiverMemberships header not found."
  end

  # Depopulate the memberships_messages jointable
  def self.de_populate_jointable(record)
    record.membership_messages.each do |mm|
      mm.destroy
    end
  end

  def self.extract_x_ecs_receiver_communities(erc)
    receiver_communities= []
    erc.split(',').map {|e| e.strip}.each do |comm_str|
      if comm_str =~ /\d{#{comm_str.length}}/
        # comm_str has only digits
        receiver_communities << comm_str.to_i
      else
        # comm_str should be a community name
        comm= Community.find_by_name(comm_str)
        if comm == nil then 
          raise Ecs::InvalidMessageException, "community id/name in X-EcsReceiverCommunities header not found: #{comm_str}"
        end
        receiver_communities << comm.id
      end
    end unless erc.blank?
    receiver_communities.uniq!
    receiver_communities
  end
    
  def self.extract_x_ecs_receiver_memberships(erm)
    receiver_memberships= []
    erm.split(',').map {|e| e.strip}.each do |memb_str|
      if memb_str =~ /\d{#{memb_str.length}}/
        # memb_str has only digits
        #receiver_memberships.concat Membership.find(memb_str.to_i).community.memberships.map{ |m| m.id }
        receiver_memberships << memb_str.to_i if  Membership.find(memb_str.to_i)
      else
        # memb_str is invalid, because it's not an integer value
        # raise Exception
      end
    end unless erm.blank?
    receiver_memberships.uniq!
    receiver_memberships
  end


private

  # Deletes all records with relations between a record and the given
  # memberships or all record with relation to the given message
  # (memberships=nil)
  def self.delete_relations(message, memberships=nil)
    if memberships
      memberships.each do |m|
        destroy_all ["membership_id = ? and message_id = ?", m.id, message.id]
      end
    else
      destroy_all ["message_id = ?", message.id]
    end
  end

end
