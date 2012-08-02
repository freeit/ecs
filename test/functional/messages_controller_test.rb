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

class MessagesControllerTest < ActionController::TestCase
  test "index" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    get :index
    assert_response 200
    assert_equal [1,2], assigns(:list).map {|e| e.id}
  end

  test "show first exercise as a receiver" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    get :show, { :id => messages(:numlab_ex1).id }
    assert_response 200
    assert_equal "Hallo Ihr da im Radio.", @response.body.strip
    assert_equal "X-EcsSender: "+memberships(:stgt_wuv).id.to_s, "X-EcsSender: "+@response.header['X-EcsSender']
    assert_equal "X-EcsReceiverCommunities: "+communities(:wuv).id.to_s, "X-EcsReceiverCommunities: "+@response.header['X-EcsReceiverCommunities']
  end

  test "show solution" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/solutions/3")
    get :show, { :id => messages(:numlab_sol).id }
    logger.debug "request.path = #{@request.path}"
    logger.debug "app_namespace = #{assigns(:app_namespace)}"
    logger.debug "ressource_name = #{assigns(:ressource_name)}"
    assert_response 200
  end

  # not a receiver or sender of :numlab_ex1
  test "show forbidden exercise" do
    @request.env["X-EcsAuthId"] = identities(:numlab_comp_id1).name
    @request.set_REQUEST_URI("/numlab/exercises/#{messages(:numlab_ulm_ex1).id.to_s}")
    get :show, { :id => messages(:numlab_ulm_ex1).id }
    logger.debug "request.path = #{@request.path}"
    assert_response 403
  end

  test "show exercise as original sender but not as a receiver" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    get :show, { :id => messages(:numlab_ulm_ex1).id }
    logger.debug "request.path = #{@request.path}"
    assert_response 200
    assert !@response.header.has_key?('X-EcsSender')
    assert !@response.header.has_key?('X-EcsReceiverCommunities')
  end

  test "create_X-EcsReceiverMemberships" do
    @request.env["RAW_POST_DATA"] = "hallole"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    @request.set_REQUEST_URI("/numlab/exercises")
    mm_count = MembershipMessage.all.count
    post :create
    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+1, MembershipMessage.all.count
    assert_match /^.*\/numlab\/exercises\/[0-9]+$/, @response.header['LOCATION']
  end

  test "create_X-EcsReceiverCommunities_single" do
    @request.env["RAW_POST_DATA"] = "hallole"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverCommunities"] = communities(:suv).name
    mm_count = MembershipMessage.all.count
    post :create

    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+1, MembershipMessage.all.count
  end

  test "create_X-EcsReceiverCommunities_multi" do
    @request.env["RAW_POST_DATA"] = "hallole"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverCommunities"] = communities(:suv).name + "," + communities(:public).name
    mm_count = MembershipMessage.all.count
    post :create
    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+3, MembershipMessage.all.count
  end

  test "create_X-EcsReceiverCommunities_multi_string_and_number" do
    @request.env["RAW_POST_DATA"] = "hallole"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverCommunities"] = communities(:suv).name + "," + communities(:public).id.to_s
    mm_count = MembershipMessage.all.count
    post :create
    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+3, MembershipMessage.all.count
  end

  test "create without content-type header" do
    @request.env["RAW_POST_DATA"] = "hallole"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    post :create
    assert_response 400
  end

  test "create without body" do
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    post :create
    assert_response 400
  end

  test "update" do
    @request.env["RAW_POST_DATA"] = "neuer Text"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    @request.set_REQUEST_URI("/numlab/exercises")
    post :update, { :id => messages(:numlab_ex2).id }
    assert_response 200
  end

  test "update with event generation" do
    @request.env["RAW_POST_DATA"] = "neuer Text"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    @request.set_REQUEST_URI("/numlab/exercises")
    ev_count = Event.all.count
    m= Message.find(messages(:numlab_ex2).id)
    m.ressource.events= true
    m.save
    post :update, { :id => messages(:numlab_ex2).id }
    assert_response 200
    assert_equal ev_count+1, Event.all.count
    ev= Event.find(:last, :order => "id")
    assert_equal ev.ev_type_id, 3
    m= Message.find(messages(:numlab_ex2).id)
    m.ressource.events= false
    m.save
  end

  test "update without ownership" do
    @request.env["RAW_POST_DATA"] = "neuer Text"
    @request.env["CONTENT_TYPE"] = "text/html"
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
    @request.set_REQUEST_URI("/numlab/exercises")
    post :update, { :id => messages(:numlab_ex2).id }
    assert_response 403
  end

  # not a receiver or sender of :numlab_sol
  test "delete_forbidden_solution" do
    @request.env["X-EcsAuthId"] = identities(:numlab_comp_id1).name
    @request.set_REQUEST_URI("/numlab/solutions/#{messages(:numlab_sol).id.to_s}")
    post :destroy, { :id => messages(:numlab_sol).id }
    logger.debug "request.path = #{@request.path}"
    assert_response 404
  end

  test "delete_postrouted_message_as_owner_with_references_in_place" do
    @request.set_REQUEST_URI("/numlab/exercises/99999")
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    assert MembershipMessage.find_all_by_message_id(messages(:numlab_ulm_ex1)).count > 0
    post :destroy, { :id => messages(:numlab_ulm_ex1).id }
    logger.debug "@request.path = "+@request.path
    assert_response 200
    get :show, { :id => messages(:numlab_ulm_ex1).id }
    assert_response 404 
    assert_equal 0, MembershipMessage.find_all_by_message_id(messages(:numlab_ulm_ex1)).count
    # message is only tagged as removed (events on). physically it's still there.
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(messages(:numlab_ulm_ex1)) }
  end

  test "delete_postrouted_message_as_none_owner_with_references_in_place" do
    @request.set_REQUEST_URI("/numlab/exercises/99999")
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    mm_count = MembershipMessage.all.count
    # destroy message through receiver and none owner
    post :destroy, { :id => messages(:numlab_ulm_ex1).id }
    logger.debug "@request.path = "+@request.path
    assert_response 200
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(@request.parameters[:id]) }
    assert_equal 0, MembershipMessage.find_all_by_message_id(@request.parameters[:id]).count
  end

  test "delete_none_postrouted_message_as_none_owner_with_last_reference_in_place" do
    @request.env["RAW_POST_DATA"] = "Diese Nachricht ist volatil.\r\n"
    @request.env["CONTENT_TYPE"] = "text/plain"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:numlab_comp).id.to_s
    @request.set_REQUEST_URI("/numlab/solutions")
    mm_count = MembershipMessage.all.count
    post :create
    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+1, MembershipMessage.all.count
    # destroy message through receiver
    @request.set_REQUEST_URI("/numlab/solutions")
    @request.env["X-EcsAuthId"] = identities(:numlab_comp_id1).name
    /[0-9]+$/ =~ @response.header['LOCATION']
    memberships = Membership.receiver(identities(:numlab_comp_id1).participant, $~.to_s.to_i)
    post :destroy, { :id => $~.to_s.to_i }
    assert_response 200
    assert_equal $~.to_s, @request.parameters[:id]
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(@request.parameters[:id]) }
    assert_nil MembershipMessage.find_by_message_id(@request.parameters[:id])
  end

  test "delete_none_postrouted_message_as_none_owner_with_references_in_place" do
    @request.env["RAW_POST_DATA"] = "Diese Nachricht ist volatil.\r\n"
    @request.env["CONTENT_TYPE"] = "text/plain"
    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
    @request.env["X-EcsReceiverMemberships"] = memberships(:numlab_comp).id.to_s+","+memberships(:numlab_teacher).id.to_s
    @request.set_REQUEST_URI("/numlab/solutions")
    mm_count = MembershipMessage.all.count
    post :create
    assert_response 201
    assert_equal assigns(:record).sender, assigns(:participant).id
    assert_equal mm_count+2, MembershipMessage.all.count
    /[0-9]+$/ =~ @response.header['LOCATION']
    assert_equal 2, MembershipMessage.find_all_by_message_id($~.to_s.to_i).count
    # destroy message through receiver
    @request.set_REQUEST_URI("/numlab/solutions")
    @request.env["X-EcsAuthId"] = identities(:numlab_comp_id1).name
    post :destroy, { :id => $~.to_s.to_i }
    assert_response 200
    assert_equal $~.to_s, @request.parameters[:id]
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(@request.parameters[:id]) }
    assert_equal 1, MembershipMessage.find_all_by_message_id($~.to_s.to_i).count
  end

  # Queue tests
  #
  test "fifo get idempotent" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    get :fifo
    assert_response 200
    assert_equal "Hallo Ihr da im Radio.", @response.body.strip
    get :fifo
    assert_response 200
    assert_equal "Hallo Ihr da im Radio.", @response.body.strip
  end

  test "fifo get not idempotent" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    post :fifo
    assert_response 200
    assert_equal "Hallo Ihr da im Radio.", @response.body.strip
    get :fifo
    assert_response 200
    assert_not_equal "Hallo Ihr da im Radio.", @response.body.strip
    assert_equal "Achtung ein Kartoon.", @response.body.strip
  end

  test "lifo get idempotent" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    get :lifo
    assert_response 200
    assert_equal "Achtung ein Kartoon.", @response.body.strip
    get :lifo
    assert_response 200
    assert_equal "Achtung ein Kartoon.", @response.body.strip
  end

  test "lifo get not idempotent" do
    @request.env["X-EcsAuthId"] = identities(:ulm_id1).name
    @request.set_REQUEST_URI("/numlab/exercises")
    post :lifo
    assert_response 200
    assert_equal "Achtung ein Kartoon.", @response.body.strip
    get :lifo
    assert_response 200
    assert_not_equal "Achtung ein Kartoon.", @response.body.strip
    assert_equal "Hallo Ihr da im Radio.", @response.body.strip
  end


#  test "create_auths" do
#    @request.env["RAW_POST_DATA"] = '{"url":"http://freeit.de/course1"}'
#    @request.env["CONTENT_TYPE"] = "application/json"
#    @request.env["X-EcsAuthId"] = identities(:stgt_id1).name
#    @request.env["X-EcsReceiverMemberships"] = memberships(:ulm_wuv).id.to_s
#    @request.set_REQUEST_URI("/sys/auths")
#    mm_count = MembershipMessage.all.count
#    post :create
#    assert_response 201
#  end


# anonymous clients
#

  test "create anonymous client" do
    @request.env["CONTENT_TYPE"] = "application/json"
    @request.set_REQUEST_URI("/numlab/exercises")
    mm_count = MembershipMessage.all.count
    get  :index
    assert_response 200
    assert_match /ecs_anonymous=.*/, @response.headers["Set-Cookie"].to_s
    assert_equal mm_count+1, MembershipMessage.all.count
  end if ECS_CONFIG["participants"]["allow_anonymous"]


end
