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
    memberships= index_querystring_list
    if memberships.empty?
      render :text => "", :content_type => "application/json", :layout => false
    else
      respond_to do |format|
        format.json { render :json => JSON.pretty_generate(memberships) }
        format.xml  { render :xml  => memberships }
      end
    end
  end

  private

  def index_querystring_list
    header_querystrings = request.headers["X-EcsQueryStrings"]
    if header_querystrings
      hqs = header_querystrings.split(",").map{|s| s.strip}.map{|s| s.split("=").map{|s| s.strip}}
      mainparticipants = (m=hqs.assoc("mainparticipants")) ? m[1] : nil
      subparticipants = (m=hqs.assoc("subparticipants")) ? m[1] : nil
      anonymous = (m=hqs.assoc("anonymous")) ? m[1] : nil
      all = (m=hqs.assoc("all")) ? m[1] : nil
    end
    mainparticipants ||= params["mainparticipants"] ? params["mainparticipants"] : nil
    subparticipants ||= params["subparticipants"] ? params["subparticipants"] : nil
    anonymous ||= params["anonymous"] ? params["anonymous"] : nil
    all ||= params["all"] ? params["all"] : nil
    Membership.memberships(@participant,false,
                           { :mainparticipants => mainparticipants,
                             :subparticipants => subparticipants,
                             :anonymous => anonymous,
                             :all => all })
  end

end
