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


class Event < ActiveRecord::Base
  belongs_to  :ev_type
  belongs_to  :participant
  belongs_to  :message

  def ===(y)
    participant_id == y.participant_id and message_id == y.message_id and ev_type_id == y.ev_type_id
  end

private

  # if count <0 then list all events otherwise maximal count events
  named_scope :for_participant, lambda { |participant_id,count| {
    :conditions => { :participant_id => participant_id },
    :order => "id ASC",
    count<0 ? :readonly : :limit => count }}
  named_scope :for_participant_and_message_desc_order, lambda { |participant_id,message_id| {
    :conditions => { :participant_id => participant_id, :message_id => message_id },
    :order => "id DESC",
    :limit => 1 }}

  def self.make(options)
    options.assert_valid_keys(:event_type_name, :membership_message, :participant, :message)
    message = options[:membership_message] ? options[:membership_message].message : options[:message]
    participant= options[:membership_message] ? options[:membership_message].membership.participant : options[:participant]
    return if not (message.ressource.events? and participant.events?)
    event = Event.new
    event.participant_id = participant.id
    event.message_id = message.id
    case options[:event_type_name]
      when "created"
        event.ev_type_id = EvType.find_by_name("created").id
      when "destroyed"
        event.ev_type_id = EvType.find_by_name("destroyed").id
      when "updated"
        event.ev_type_id = EvType.find_by_name("updated").id
      else event.ev_type_id = 7777
    end
    if unique_or_notlast?(event) and event.save
      event
    else
      # There is already a pending event (the last one) describing a change of
      # the message. So don't create another one. Instead only touch the
      # "updated_at" attribute of the event.
      iev= Event.for_participant_and_message_desc_order(event.participant_id, event.message_id)[0]
      iev.updated_at= Time.now.to_s(:db)
      iev.save
      nil
    end
  end

  def self.unique_or_notlast?(event)
    # Normally there should/could only be multiple update events more than
    # once. The testing code would also handle all other events correctly.
    mid= event.message_id
    pid= event.participant_id
    etid= event.ev_type_id
    case initial_event(pid, mid, etid)
    when nil
      # its a unique event
      return true
    when Event.for_participant_and_message_desc_order(pid, mid)[0]
      # there is already such an event for that message and its the last in the queue
      # for case equality see also overridden === case operator
      return false
    else
      # there is such an event but it's not the last in the queue so create a new one
      return true
    end
  end

  def self.initial_event(pid, mid, etid)
    Event.find_by_participant_id_and_message_id_and_ev_type_id(pid, mid, etid)
  end

end
