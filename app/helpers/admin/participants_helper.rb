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


module Admin::ParticipantsHelper

  @queryparams = [[:list_anonymous,:anonymous], [:action_buttons, :actionbuttons]]

  # adds an empty identity object to the p.identities collection. This object
  # ist still not saved. This collection is reused in the form.fields_for method.
  # (form.fields_for :identities ...)
  def setup_participant(participant)
    returning(participant) do |p|
      p.identities.build
      p.communities.build
    end
  end

  def button_to_reset(participant, list_anonymous, action_buttons)
    button_to_reset =  "button_to 'Reset', reset_admin_participant_path(:id => participant,#{(list_anonymous)?":anonymous => true":":anonymous => false"}"
    button_to_reset += ", #{(action_buttons)?":actionbuttons => true":":actionbuttons => false"})"
    button_to_reset += ", :title => 'All messages and events of \"#{h participant.name}\" participant will be deleted. #{(ECS_CONFIG["admin"]["confirm_actions"])?"":"There will be no confirmation !"}'"
    button_to_reset += ", #{(action_buttons)?":disabled => false":":disabled => true"}"
    button_to_reset += ", :confirm => 'Are you sure?'" if ECS_CONFIG["admin"]["confirm_actions"]
    eval button_to_reset
  end

  def button_to_delete(participant, list_anonymous, action_buttons)
    button_to_delete = "button_to 'Delete', admin_participant_path(:id => participant,#{(list_anonymous)?":anonymous => true":":anonymous => false"}"
    button_to_delete += ", #{(action_buttons)?":actionbuttons => true":":actionbuttons => false"})"
    button_to_delete +=", :method => :delete"
    button_to_delete +=", :title => 'The \"#{h participant.name}\" participant will be deleted. #{(ECS_CONFIG["admin"]["confirm_actions"])?"":"There will be no confirmation !"}'"
    button_to_delete += ", #{(action_buttons)?":disabled => false":":disabled => true"}"
    button_to_delete += ", :confirm => 'Are you sure?'" if ECS_CONFIG["admin"]["confirm_actions"]
    eval button_to_delete
  end

  def link_to_actions_toggle_on_off(list_anonymous, action_buttons)
    Rails.logger.info "Admin::ParticipantsHelper#link_to_actions_toggle_on_off actionbuttons = #{action_buttons}"
    link = "link_to #{(action_buttons)?'\'off\'':'\'on\''}, admin_participants_path(#{(list_anonymous)?":anonymous => true":":anonymous => false"}"
    link +=", #{(action_buttons)?":actionbuttons => false":":actionbuttons => true"})"
    unless action_buttons
      session[:link_to_actions_toggle_on_off] = false
    end
    if not session[:link_to_actions_toggle_on_off] and action_buttons
      session[:link_to_actions_toggle_on_off] = true
      unless ECS_CONFIG["admin"]["confirm_actions"]
        flash.now[:notice] = "Action buttons operate in NON CONFIRMATION mode, .i.e. pressing a delete or reset button just do its job without any confirmation. You have been warned ! To change this behaviour, just set \"admin->confirm_actions\" to \"true\" in \"config/ecs_config.yml\"." 
      end
    end
    eval link
  end

  def link_to_anonymous_toggle_on_off(list_anonymous, action_buttons)
  end

  def toggle_query_param(queryparam)
  end

  def link_to_toggle_on_off(ontext, offtext, list_anonymous, action_buttons)
    #link = "link_to #{(action_buttons)?\'offtext\':\'ontext\'}, admin_participants_path(#{(list_anonymous)?":anonymous => true":":anonymous => false"}"
    #link +=", #{(action_buttons)?":actionbuttons => false":":actionbuttons => true"})"
    #eval link
  end

end
