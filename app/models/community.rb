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


class Community < ActiveRecord::Base
  has_many  :memberships, :order => :id
  has_many  :participants, :through => :memberships do
    def with_reduced_attributes_and_without_anonymous
      find  :all, :select => "participants.id, name, description, email, dns, organization_id",
            :conditions => ["participants.anonymous = ?", false],
            :order => "participants.id ASC"
    end
  end
  has_many :community_messages, :dependent => :destroy
  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :for_participant, lambda { |participant| {
    :joins => [:memberships => :participant],
    :conditions => { :participants => { :id => participant.id }}}}

  named_scope :for_message, lambda { |message| {
    :joins => [:memberships => {:membership_messages => :message}],
    :conditions => { :messages => { :id => message.id }}}}


end
