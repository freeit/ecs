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


require 'test_helper'


class Admin::ParticipantsControllerTest < ActionController::TestCase
  TTL = 3600 # seconds, how long an anonymous participant lives
  test "create participant and postrouting" do
    params = {
      :participant => {
        "name"=> "testclient",
        "identities_attributes"=>{"0"=>{"name"=>"test", "description"=>"only for test"}},
        "community_ids"=>[communities(:wuv).id],
        "description"=>"Dieser Participant wird zum Testen kreiert.",
        "dns"=>"N/A",
        "organization_id"=>Organization.find_by_name("not available").id,
        "email"=>"N/A",
        "ttl"=> DateTime.now.utc + TTL.seconds,
        "anonymous"=>false,
        "community_selfrouting"=>false
      }
    }
    assert_difference('Participant.count') do
      post :create, params
    end
    assert_equal('Participant was successfully created.',flash[:notice])
    assert_equal(communities(:wuv).id, Participant.find_by_name("testclient").communities.first.id)
    assert_equal(1,Participant.find_by_name("testclient").memberships.first.membership_messages.count)
  end
end
