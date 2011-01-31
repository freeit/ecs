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


ActionController::Routing::Routes.draw do |map|

  map.namespace(:admin) do |admin|
    admin.resources :participants
    admin.resources :communities, :has_many => :participants
    admin.resources :organizations
    admin.resources :ressources
  end

  map.resources :memberships, :only => [:index]
  map.resources :events, :only => [:index],
                :collection => { :fifo => [:get, :post] }

  begin
    Ressource.all.each do |r|
      map.resources r.ressource.to_sym, :path_prefix => '/'+r.namespace,
      :name_prefix => r.namespace+'_', :controller => 'messages',
      :only => [:index, :show, :create, :update, :destroy],
      :collection => { :fifo => [:get, :post], :lifo => [:get, :post] }
    end
  rescue ActiveRecord::StatementInvalid 
    Rails.logger.info "DB error: #{$!}"
  end

  map.connect '/admin', :controller => 'admin/participants', :action => 'default'
  map.root :controller => 'admin/participants', :action => 'default'
end
