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


class Ressource < ActiveRecord::Base
  has_many :messages, :dependent => :destroy
  validates_presence_of :namespace, :ressource 
  after_save :rebuild_routes
  after_destroy :rebuild_routes

  named_scope :list, :order => "namespace, ressource ASC"

  def self.validates_ressource_path(namespace, ressource)
    r = Ressource.find_by_namespace_and_ressource(namespace, ressource)
    raise(Ecs::InvalidRessourceUriException, "*** ressource uri error ***") unless r
    if namespace.blank? or r.namespace.blank?
      raise Ecs::InvalidRessourceUriException, "*** namespace error ***"
    end
    if ressource.blank? or r.ressource.blank?
      raise Ecs::InvalidRessourceUriException, "*** ressource name error ***"
    end
    return r
  end

  def events?
    self.events.blank? ? false : true
  end

private

  def rebuild_routes
    logger.info("rebuild routes")
    ActionController::Routing::Routes.reload!
  end

end
