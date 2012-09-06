# Copyright (C) 2007, 2008, 2009, 2010, 2011, 2012
# Heiko Bernloehr (FreeIT.de).
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

Organization.create :name => "not available",
  :description => "For anonymous participants.",
  :abrev => "n/a" if Organization.find_by_name("not available").nil?
Organization.create :name => "system",
  :description => "Internal ECS community.",
  :abrev => "sys" if Organization.find_by_name("system").nil?
Participant.create :name => "ecs",
  :description => "ECS system participant",
  :dns => 'n/a',
  :community_selfrouting => false,
  :organization_id => Organization.find_by_name("system").id if Participant.find_by_name("ecs").nil?
Community.create :name => "public",
  :description => "For anonymous participants." if Community.find_by_name("public").nil?
%w(created destroyed updated notlinked).each do |evt|
  EvType.create :name => evt if EvType.find_by_name(evt).nil?
end
Ressource.create :namespace => 'sys',
  :ressource => 'auths',
  :postroute => true,
  :events => false if Ressource.find_by_namespace_and_ressource("sys","auths").nil?
