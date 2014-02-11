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


class Admin::CommunitiesController < ApplicationController

  include Admin::Helper

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => [ :post, :put, :delete ], :only => [ :destroy, :create, :update, :destroy_participant ],
         :add_flash => { :notice => "Failed to execute last action" },
         :redirect_to => :index_admin_communities_path

  def index
    list
    render :action => 'list'
  end

  def list
    @communities=Community.find(:all).uniq
  end

  def show
    @community = Community.find(params[:id])
  end

  def new
    @community = Community.new
  end

  def create
    @community = Community.new(params[:community])
    if @community.save
      flash[:notice] = 'Community was successfully created.'
      redirect_to admin_community_path(@community)
    else
      render :action => 'new'
    end
  end

  def edit
    @community = Community.find(params[:id])
  end

  def update
    @community = Community.find(params[:id])
    if @community.update_attributes(params[:community])
      flash[:notice] = 'Community was successfully updated.'
      redirect_to admin_community_path(@community)
    else
      render :action => 'edit'
    end
  end

  def destroy
    Community.find(params[:id]).destroy
    redirect_to admin_communities_path
  end

  # lists all participants of the community
  def index_participants
    @community = Community.find(params[:id])
    @participants=Community.find(params[:id]).memberships.collect {|i| i.participant  }.uniq.sort{|x,y| x.id <=> y.id }
  end

  # lists all those participants which has not joined the community
  def index_nonparticipants
    index_participants
    @participants=(Participant.find(:all) - @participants).sort{|x,y| x.id <=> y.id }
  end

  # community releases a participant
  def destroy_participant
    destroy_membership(params[:id], params[:p_id])
    redirect_to admin_community_participants_path(:id=>params[:id])
  end

  # community invites a participant
  def create_participant
    create_membership(params[:id], params[:p_id])
    redirect_to index_admin_community_nonparticipants_path(:id=>params[:id])
  end

end
