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


class Admin::RessourcesController < ApplicationController
  require 'pp'

  include Admin::Helper

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => [ :post, :put, :delete ], :only => [ :destroy, :create, :update ],
         :add_flash => { :notice => "Failed to execute last action" },
         :redirect_to => :admin_ressources_path

  def index
    list
    render :action => 'list'
  end
  
  def list 
    @ressources = Ressource.list
    @list_ressources_count = @ressources.count
  end
  
  def show
    @ressource = Ressource.find(params[:id])
  end
  
  def new
    @ressource = Ressource.new
  end
  
  def create
    @ressource = Ressource.new(params[:ressource])
    if @ressource.save
      flash[:notice] = 'Ressource was successfully created.'
      redirect_to admin_ressources_path
    else 
      render :action => 'new'
    end
  end
  
  def edit
    @ressource = Ressource.find(params[:id])
  end
  
  def update
    #params[:participant][:community_ids] ||= []
    @ressource = Ressource.find(params[:id])
    if @ressource.update_attributes(params[:ressource])
      flash[:notice] = 'Ressource was successfully updated.'
      redirect_to admin_ressources_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Ressource.find(params[:id]).destroy
    redirect_to admin_ressources_path 
  end
  
end
