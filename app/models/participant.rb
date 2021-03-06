# Copyright (C) 2007, 2008, 2009, 2010, 2014 Heiko Bernloehr (FreeIT.de).
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


class Participant < ActiveRecord::Base
  TTL = 1.hour # how long an anonymous participant lives
  TYPE={ :main => "main", :sub => "sub", :anonym => "anonym" }

  after_destroy :delete_messages

  belongs_to  :organization
  # TODO: warn user about possible deletions of messages.
  has_many    :memberships, :dependent => :destroy
  has_many    :communities, :through => :memberships
  has_many    :identities, :dependent => :destroy
  has_many    :events, :dependent => :destroy
  has_many    :childs,
              :order => "id ASC",
              :class_name => "Subparticipant",
              :foreign_key => "parent_id",
              :dependent => :destroy
  has_one     :subparticipant, :dependent => :destroy

  validates_presence_of :name, :organization_id
  validates_uniqueness_of :name

  accepts_nested_attributes_for :identities, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :communities, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :subparticipant, :allow_destroy => true

  named_scope :order_id_asc, :order => "participants.id ASC"
  named_scope :without_anonymous, :conditions => { :participants => { :anonymous => false } }
  named_scope :anonymous, :conditions => { :participants => { :anonymous => true } }
  named_scope :for_message, lambda { |message| {
    :joins => [:memberships => {:membership_messages => :message}],
    :conditions => {:messages => {:id => message.id}}}}
  named_scope :for_community, lambda { |community| {
    :joins => [:memberships => :community],
    :conditions => { :communities => { :id => community.id }}}}
  named_scope :for_subparticipants
  named_scope :itsyou, lambda { |itsyoupid| { :conditions => { :participants => { :id => itsyoupid } } } }
  named_scope :only_subparticipants, :conditions => { :participants => { :ptype => TYPE[:sub] } }
  named_scope :only_mainparticipants, :conditions => { :participants => { :ptype => TYPE[:main] } }
  named_scope :only_anonymous, :conditions => { :participants => { :ptype => TYPE[:anonym] } }

  def self.reduced_attributes
    find  :all, :select => "participants.id, participants.name, participants.description, participants.email, participants.dns, participants.organization_id, participants.ptype"
  end

  def self.mainparticipants_with_reduced_attributes
    only_mainparticipants.order_id_asc.reduced_attributes
  end

  def self.subparticipants_with_reduced_attributes
    only_subparticipants.order_id_asc.reduced_attributes
  end

  def self.anonymous_participants_with_reduced_attributes
    only_anonymous.order_id_asc.reduced_attributes
  end

  def destroy_receiver_messages
    Message.for_participant_receiver(self).each do |m|
      m.destroy_as_receiver(self)
    end
  end

  def destroy_sender_messages
    Message.for_participant_sender(self).each do |m|
      m.destroy_as_sender
    end
  end

  def destroy_events
    self.events.each do |e|
      e.destroy
    end
  end

  def mainparticipant?
    if not anonymousparticipant? and subparticipant.nil?
      true
    else
      false
    end
  end

  def subparticipant?
    if not anonymousparticipant? and not subparticipant.nil?
      true
    else
      false
    end
  end

  def anonymousparticipant?
    anonymous?
  end

  # test if the participant is the initial sender of the message in question.
  def sender?(message)
    if message.sender == id
      true
    else
      false
    end
  end

  def receiver?(message)
    not Membership.receiver(id, message.id).empty?
  end

  def events?
    self.events_.blank? ? false : true
  end

  def anonymous?
    anonymous
  end

  def self.generate_anonymous_participant
    cookie = Digest::SHA1.hexdigest('something secret'+Time.now.to_s+rand.to_s)
    params = {
        "name"=> "#{cookie}",
        "identities_attributes"=>{"0"=>{"name"=>"#{cookie}", "description"=>"Cookie Identifier"}},
        "community_ids"=>[Community.find_by_name("public").id],
        "description"=>"Anonymous Participant",
        "dns"=>"N/A",
        "organization_id"=>Organization.find_by_name("not available").id,
        "email"=>"N/A",
        "ttl"=> DateTime.now.utc + TTL,
        "anonymous"=>true,
        "ptype"=>TYPE[:anonym]
    }
    ap = new(params)
    ap.save!
    return ap, cookie
  end

  def self.touch_ttl(participant)
    participant.ttl = DateTime.now.utc + TTL
    participant.save
  end

  def mid(community)
    Membership.for_participant_id_and_community_id(self, community.id).first.id
  end

private

  def delete_messages
    Message.destroy_all(["sender = ?", self.id])
  end

end
