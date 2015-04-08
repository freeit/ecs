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


class Membership < ActiveRecord::Base
  belongs_to  :participant
  belongs_to  :community
  belongs_to  :community_with_reduced_attributes,
              :class_name => "Community",
              :foreign_key => "community_id",
              :select => "name, description, id"
  has_many    :messages, :through => :membership_messages
  has_many    :membership_messages, :dependent => :destroy

  after_create  :postroute

  # returns memberships of the relation between a participant and a message
  # if no relationship then returns empty array.
  named_scope :receiver, lambda { |participant_id,message_id| {
    :joins => [:participant, {:membership_messages => :message}],
    :conditions => { :participants => { :id => participant_id }, :messages => { :id => message_id } } } }

  named_scope :receivers, lambda { |message_id| {
    :joins => [:membership_messages => :message],
    :select => :memberships.to_s+".id" + ", community_id, participant_id",
    :conditions => { :messages => { :id => message_id } } } }

  named_scope :for_participant_id, lambda { |participant_id| {
    :joins => [:participant],
    :conditions => { :participants => { :id => participant_id } } } }

  named_scope :for_participant_id_and_community_id, lambda { |participant_id,community_id| {
    :joins => [:participant, :community],
    :conditions => { :participants => { :id => participant_id }, :communities => { :id => community_id } } } }

  def self.senders(participant, message)
    sender_mids=[]
    Community.for_participant(participant).for_message(message).uniq.each do |comm|
      sender_mids << Membership.find_by_participant_id_and_community_id(participant.id,comm.id)
    end
    if sender_mids.empty?
      []
    else
      sender_mids.flatten
    end
  end

  def self.memberships(participant,itsyou=false)
    memberships = []
    Membership.for_participant_id(participant.id).each do |membership|
        community= lambda { |memb|
                            attribs = memb.community_with_reduced_attributes.attributes
                            id = attribs["id"]; attribs.delete("id"); attribs["cid"] = id
                            attribs
                          }.call(membership)
        logger.debug "**** Membership::memberships: community: #{community.inspect}"
        if itsyou
          participants_with_reduced_attribs= membership.community.participants.itsyou(participant.id).without_anonymous.reduced_attributes
          logger.debug "**** Membership::memberships: participants_with_reduced_attribs: #{participants_with_reduced_attribs.inspect}"
        else
          participants_with_reduced_attribs= membership.community.participants.without_anonymous.reduced_attributes
        end
        participants= participants_with_reduced_attribs.map do |p|
          attribs = p.attributes
          attribs["mid"] = Membership.for_participant_id_and_community_id(p.id, membership.community.id).first.id
          attribs["org"] = {"name" => p.organization.name, "abbr" => p.organization.abrev}
          attribs["itsyou"] = p.id == participant.id
          attribs["pid"] = p.id
          attribs.delete("id")
          attribs.delete("organization_id")
          attribs
        end
        logger.debug "**** Membership::memberships: participants: #{participants.inspect}"
        memberships <<
          { :community => community,
            :participants => participants
          }
    end
    memberships
  end

private

  # generate created events for all messages connected to this community membership
  def postroute
    community.messages.map{|m| m.ressource.postroute ? m : nil}.compact.each do |msg|
      messages << msg
      Event.make(:event_type_name => EvType.find_by_name("created").name, :participant => participant, :message => msg)
      logger.info "**** postrouting message.id=#{msg.id} to participant:#{participant.name} (pid:#{participant.id})"
    end
  end

end
