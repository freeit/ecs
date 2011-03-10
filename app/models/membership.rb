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

  # returns memberships of the relation between a participant and a message
  # if no relationship then returns empty array.
  named_scope :receiver, lambda { |participant_id,message_id| {
    :joins => [:participant, {:membership_messages => :message}], 
    :conditions => { :participants => { :id => participant_id }, :messages => { :id => message_id } } } }

  named_scope :for_participant_id, lambda { |participant_id| {
    :joins => [:participant],
    :conditions => { :participants => { :id => participant_id } } } }

  named_scope :for_participant_id_and_community_id, lambda { |participant_id,community_id| {
    :joins => [:participant, :community],
    :conditions => { :participants => { :id => participant_id }, :communities => { :id => community_id } } } }
end
