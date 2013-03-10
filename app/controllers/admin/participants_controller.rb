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


class Admin::ParticipantsController < ApplicationController

  require 'pp'

  include Admin::Helper

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => [ :post, :put, :delete ], :only => [ :destroy, :create, :update, :destroy_participant ],
         :add_flash => { :notice => "Failed to execute last action" },
         :redirect_to => :admin_participants_path

  def default
    redirect_to admin_participants_path
  end

  def index
    list
    render :action => 'list'
  end
  
  def list 
    @list_participants_anonymous_count = Participant.all.count - Participant.without_anonymous.count
    @participants = case params[:anonymous]
      when "true" 
        @list_anonymous=true
        @list_participants_count = Participant.all.count
        Participant.find(:all).uniq
      when "false"
        @list_anonymous=false
        @list_participants_count = Participant.all.count - @list_participants_anonymous_count
        Participant.without_anonymous.uniq
      else
        @list_anonymous=false
        @list_participants_count = Participant.all.count - @list_participants_anonymous_count
        Participant.without_anonymous.uniq
    end
  end
  
  def show
    @participant = Participant.find(params[:id])
  end
  
  def new
    @participant = Participant.new
    @organizations = Organization.find(:all, :order => :id)
    @participant.identities.build
  end
  
  def create
    @participant = Participant.new(params[:participant])
    if @participant.save
      flash[:notice] = 'Participant was successfully created.'
      redirect_to admin_participants_path
    else 
      @organizations = Organization.find(:all, :order => :id)
      render :action => 'new'
    end
  end
  
  def edit
    @participant = Participant.find(params[:id])
    @organizations = Organization.find(:all, :order => :id)
  end
  
  def update
    params[:participant][:community_ids] ||= []
    @organizations = Organization.find(:all, :order => :id)
    @participant = Participant.find(params[:id])
    lmsgs= leaved_messages(@participant, params[:participant][:community_ids])
    if @participant.update_attributes(params[:participant])
      generate_destroyed_events_by_leaving_a_community(@participant,lmsgs) unless lmsgs.blank?
      flash[:notice] = 'Participant was successfully updated.'
      redirect_to admin_participant_url(:id => @participant)
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Participant.find(params[:id]).destroy
    flash[:notice] = 'Participant was successfully destroyed.'
    redirect_to admin_participants_path 
  end
  
  def index_communities
    @participant = Participant.find(params[:id])
    @communities=Participant.find(params[:id]).memberships.collect {|i| i.community  }.uniq.sort{|x,y| x.id <=> y.id }
  end

  # lists all those communities which the participant has not yet joined
  def index_noncommunities
    index_communities
    @communities=(Community.find(:all) - @communities).sort{|x,y| x.id <=> y.id }
  end

  def destroy_community
    destroy_membership(params[:c_id], params[:id])
    redirect_to admin_participant_communities_path(params[:id])
  end


  # join to a community
  def create_community
    create_membership(params[:c_id], params[:id])
    redirect_to admin_participant_communities_path(params[:id])
  end
  
private

  # Generate destroyed events for all messages unconnected in respect to the
  # leaving communities.
  def generate_destroyed_events_by_leaving_a_community(participant, messages )
    messages.each do |msg|
      Event.make(:event_type_name => EvType.find_by_name("destroyed").name, :participant => participant, :message => msg)
      logger.info "destroyed event for message.id=#{msg.id}, participant:#{participant.name} (pid:#{participant.id})"
    end
  end

  def leaved_messages(participant, community_ids)
    leaved_community_ids= participant.communities.map{|c| c.id} - community_ids.map{|p| p.to_i}
    leaved_messages= []
    leaved_community_ids.each do |cid|
      leaved_messages << Membership.find_by_participant_id_and_community_id(participant.id, cid).messages
      leaved_messages << Community.find(cid).messages
    end
    leaved_messages.flatten.compact.uniq
  end

end
