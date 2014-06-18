# Copyright (C) 2014 Heiko Bernloehr (FreeIT.de).
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

class SubparticipantsController < ApplicationController

  require 'json/add/rails'

  before_filter :authentication
  before_filter :block_anonymous_participants
  before_filter :block_subparticipants
  before_filter :check_json_contenttype, :only => :create
  before_filter :check_parent, :only => [:show, :destroy, :update]

  def initialize
    super
  end

  def index
    childs= @participant.childs
    childs.each do |child| 
      @body << "subparticipants/" << child.id.to_s << "\n"
    end unless childs.empty?
    respond_to do |format|
      format.text { render :text => @body, :content_type => "text/uri-list" }
    end
  end

  def show
    subparticipant= Subparticipant.find(params[:id])
    body= show_render(subparticipant)
    respond_to do |format|
      format.json { render :json  => JSON.pretty_generate(body) + "\r\n" }
      format.xml  { render :xml   => body }
    end
  end

  def create
    sender= @participant
    begin
      json_data= ActiveSupport::JSON.decode request.raw_post
    rescue StandardError
      raise Ecs::InvalidMessageException, "You have provided invalid JSON data (SubparticipantsController#create)."
    end unless request.raw_post.empty?
    subparticipant= Subparticipant.generate(sender, json_data)
    body= show_render(subparticipant)
    respond_to do |format|
      format.json { render :json  => JSON.pretty_generate(body) + "\r\n", :location => location(subparticipant) }
      format.xml  { render :xml   => body, :location => location(subparticipant) }
    end
  end

  def update
    begin
      json_data= ActiveSupport::JSON.decode request.raw_post
    rescue StandardError
      raise Ecs::InvalidMessageException, "You have provided invalid JSON data (SubparticipantsController#update)."
    end unless request.raw_post.empty?
    sender= @participant
    subparticipant= Subparticipant.find(params[:id])
    subparticipant.update__(sender, json_data, subparticipant)
    body= show_render(subparticipant)
    respond_to do |format|
      format.json { render :json  => JSON.pretty_generate(body) + "\r\n", :location => location(subparticipant) }
      format.xml  { render :xml   => body, :location => location(subparticipant) }
    end
  end

  def destroy
    subparticipant= Subparticipant.find(params[:id])
    subparticipant.participant.destroy
    render :text => "", :layout => false, :status => 200, :content_type => :json
  end

private

  def show_render(subparticipant)
    participant= subparticipant.participant
    data = nil
    data= \
      { 
        :name => participant.name,
        :description => participant.description,
        :auth_ids => participant.identities.map{|ident| {:auth_id=>ident.name, :desc=>ident.description}},
        :dns => participant.dns,
        :email => participant.email,
        :community_selfrouting => participant.community_selfrouting,
        :events => participant.events_,
        :communities => participant.communities.map{|c| c.name},
        :realm => subparticipant.realm,
      }
    data
  end

  def check_parent
    subparticipant= Subparticipant.find(params[:id])
    unless @participant.childs.include?(subparticipant)
      raise Ecs::AuthorizationException, "You are not allowed to access this subparticipant because you are not its parent/creator."
    end
  end

  def check_communities
    
  end

  def location(subparticipant)
    location = request.protocol + request.host
    location += ":" + request.port.to_s unless [80, 443].include?(request.port)
    location += request.headers["SCRIPT_NAME"] if request.headers.has_key?("SCRIPT_NAME")
    location += request.path.gsub(/\/*$/,'') + "/" + subparticipant.id.to_s
    location
  end

end
