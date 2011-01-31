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


class MembershipsController < ApplicationController

  require 'json/add/rails'

  before_filter :authentication
  before_filter :add_cookie_header # only for anonymous participants

  def initialize
    super
  end

  def index
    memberships = []
    Membership.for_participant_id(@participant.id).each do |membership|
        memberships << 
          { :community => membership.community_with_reduced_attributes.attributes,
            :participants => membership.community.participants.with_reduced_attributes_and_without_anonymous.map {|p|
              attribs = p.attributes
              attribs["mid"] = Membership.for_participant_id_and_community_id(p.id, membership.community.id).first.id
              attribs.delete("id")
              attribs
            }
          }
    end

    respond_to do |format|
      format.json { render :json => JSON.pretty_generate(memberships) }
      format.xml  { render :xml  => memberships }
    end
  end

end
