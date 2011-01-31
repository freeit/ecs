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

private

  # if count <0 then list all events otherwise maximal count events
  named_scope :for_participant, lambda { |participant_id,count| {
    :conditions => { :participant_id => participant_id },
    :order => "id ASC",
    count<0 ? :readonly : :limit => count }}


  def self.make(options)
    options.assert_valid_keys(:event_type_name, :membership_message, :participant, :message)
    message = options[:membership_message] ? options[:membership_message].message : options[:message]
    return unless message.ressource.events
    event = Event.new
    event.participant_id = options[:membership_message] ? options[:membership_message].membership.participant.id : options[:participant].id
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
    if unique?(event) and event.save
      event
    else
      nil
    end
  end

  def self.unique?(event)
    Event.find_by_participant_id_and_message_id_and_ev_type_id(event.participant_id, event.message_id, event.ev_type_id).blank? 
  end

end
