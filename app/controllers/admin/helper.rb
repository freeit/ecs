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


module Admin::Helper

  # defining a RouteSet
  #rs=ActionController::Routing::Routes


  # Participant leaves Community or Community releases Participant
  def destroy_membership(community_id, participant_id) 
    membership=Membership.find_by_community_id_and_participant_id(community_id, participant_id)    
    if membership.destroy
      flash[:notice] = "Participant \"#{Participant.find(participant_id).name}\" successfully left Community \"#{Community.find(community_id).name}\"."
    else
      flash[:notice] = "Participant \"#{Participant.find(participant_id).name}\" could not leave Community \"#{Community.find(community_id).name}\"."
    end
  end

  # Participant joins Community or Community invites Participant
  def create_membership(community_id, participant_id)
    Participant.find(participant_id).communities << Community.find(community_id)
    flash[:notice] = "Participant \"#{Participant.find(participant_id).name}\" successfully joined Community \"#{Community.find(community_id).name}\"."
  end


  def reset_the_session_key
    reset_session
  end


end
