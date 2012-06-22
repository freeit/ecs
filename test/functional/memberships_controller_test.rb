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

class MembershipsControllerTest < ActionController::TestCase

  test "prettyfied memberships" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/sys/memberships")
    @request.env["ACCEPT"] = "application/json"
    get  :index
    assert_response 200
    f = StringIO.open @response.body
    b = f.readlines
    f.close
    assert b.length > 1, "/memberships representation is not prettyfied json.\nMaybe json-pretty doesn't work.\nMaybe old gems ? Especially the json gem."
  end

end
