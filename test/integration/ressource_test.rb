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

class RessourceTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    # delete all messages for sender and receiver_1

  end

  BODY_DATA = "hallole"

  def sender_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:stgt_id1).participant
    @headers["X-EcsAuthId"] = identities(:stgt_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:suv).name
    @headers["X-EcsReceiverMemberships"] = ""
  end

  def sender2_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:stgt_id1).participant
    @headers["X-EcsAuthId"] = identities(:stgt_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:public).name
    @headers["X-EcsReceiverMemberships"] = ""
  end

  def receiver_1_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:ulm_id1).participant
    @headers["X-EcsAuthId"] = identities(:ulm_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:suv).name
  end

  def receiver_2_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:numlab_teacher_id1).participant
    @headers["X-EcsAuthId"] = identities(:numlab_teacher_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:public).name
  end

  def receiver_3_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:numlab_comp_id1).participant
    @headers["X-EcsAuthId"] = identities(:numlab_comp_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:public).name
  end

  def test_community_selfrouting
    sender_headers
    @participant.community_selfrouting=true;@participant.save!
    location = ""
    post '/numlab/exercises', BODY_DATA, @headers
    assert_response 201
    location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
    logger.info('headers["Location"]: '+headers["Location"])
    logger.info('location: '+location)
    sender_headers
    get '/numlab/exercises', nil, @headers
    assert_response 200 
    assert response.body.index(location)
  end

  def test_community_no_selfrouting
    sender_headers
    location = ""
    @participant.community_selfrouting=false;@participant.save!
    post '/numlab/exercises', BODY_DATA, @headers
    assert_response 201
    location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
    logger.info('headers["Location"]: '+headers["Location"])
    logger.info('location: '+location)
    sender_headers
    assert !@participant.community_selfrouting
    get '/numlab/exercises', nil, @headers
    assert_response 200 
    assert_nil response.body.index(location)
  end




  # events true
  # postrouted true
  # community_selfrouting false
  #
  # 1.0 Create exercise.
  #  1.1 Test index of sender and other receivers.
  #      The new exercise should be shown on all indexes.
  #  1.2 Test via GET /numlab/exercises/lifo of sender and other receivers.
  #      The new exercise should only be shown by receivers not by sender.
  #  1.3 Test via GET /numlab/exercises/<id> of sender and other receivers.
  #      The new exercise should be shown by sender and other receivers.
  #  1.4 Test if all receiver participants get an "created" event.
  #      The new event should be shown by sender and other receivers.
  #  1.5 Pop sender and all receiver events.
  def test_create
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.postroute=true;r.save!
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.events=true;r.save!
    # 1.0
    sender_headers
    location = ""
    post '/numlab/exercises', BODY_DATA, @headers
    assert_response 201
    location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
    logger.info('headers["Location"]: '+headers["Location"])
    logger.info('location: '+location)
    # 1.1
    sender_headers
    get '/numlab/exercises', nil, @headers
    assert_response 200 
    assert_nil response.body.index(location)
    receiver_1_headers
    get '/numlab/exercises', nil, @headers
    assert_response 200 
    assert response.body.index(location)
    # 1.2
    sender_headers
    get '/numlab/exercises/lifo', nil, @headers
    assert_response 200 
    assert_nil response.body.index(BODY_DATA)
    receiver_1_headers
    get '/numlab/exercises/lifo', nil, @headers
    assert_response 200 
    assert response.body.index(BODY_DATA)
    # 1.3
    sender_headers
    get '/numlab/'+location, nil, @headers
    assert_response 200 
    assert response.body.index(BODY_DATA)
    receiver_1_headers
    get '/numlab/'+location, nil, @headers
    assert_response 200 
    assert response.body.index(BODY_DATA)
    # 1.4 
    sender_headers
    get '/events', nil, @headers
    assert_response 200 
    assert_nil response.body.index(/.*?#{location}.*?created.*/)
    receiver_1_headers
    get '/events', nil, @headers
    assert_response 200 
    assert response.body.index(/.*?#{location}.*?created.*/)
    # 1.5
    sender_headers
    post '/events/fifo', nil, @headers
    logger.info("response body:\n"+response.body)
    assert_response 200 
    assert_nil response.body.index(location)
    sender_headers
    post '/events/fifo', nil, @headers
    assert_response 200 
    assert_nil response.body.index(location)
    receiver_1_headers
    post '/events/fifo', nil, @headers
    assert_response 200 
    assert response.body.index(location)
    receiver_1_headers
    get '/events/fifo', nil, @headers
    assert_response 200 
    assert_nil response.body.index(location)
  end

  # events true/false
  # postrouted true/false
  #
  # 1.0 Delete exercise through the owner.
  #  1.1 Test index of sender and other receivers.
  #      There shoudn't be any exercise on the index
  #  1.2 Test if all receiver participants get an "destroyed" event.
  #  1.3 Test if the deleted ressource is still in message table if events true
  #      otherwise the message shoud have been removed.
  # 2.0 Pop all receiver destroyed events.
  #  2.1 Test if the ressource was deleted from message table.
  def test_delete_as_owner
    p = lambda do |ev|
      # 1.0
      sender_headers
      location = ""
      post '/numlab/exercises', BODY_DATA, @headers
      assert_response 201
      location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
      sender_headers
      delete '/numlab/'+location, nil, @headers
      assert_response 200
      # 1.1
      sender_headers
      get '/numlab/exercises', nil, @headers
      assert_response 200
      assert_nil response.body.index(location)
      receiver_1_headers
      get '/numlab/exercises', nil, @headers
      assert_response 200
      assert_nil response.body.index(location)
      # 1.2
      sender_headers
      get '/events', nil, @headers
      assert_response 200
      assert_nil(response.body.index(/.*?#{location}.*?destroyed.*/))
      receiver_1_headers
      get '/events', nil, @headers
      assert_response 200
      if ev
          assert(response.body.index(/.*?#{location}.*?destroyed.*/))
        else
          assert_nil(response.body.index(/.*?#{location}.*?destroyed.*/))
      end
      # 1.3
      id = location.sub(/.*\/(.*)$/,'\1').to_i
      if ev
          assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
          assert(Message.find(id).removed)
        else
          assert_raise(ActiveRecord::RecordNotFound) { Message.find(id) }
      end
      # 2.0
      sender_headers
      post '/events/fifo', nil, @headers # created event
      assert_response 200 
      assert_nil(response.body.index(/.*?#{location}.*?created.*/))
      sender_headers
      post '/events/fifo', nil, @headers # destroyed event
      assert_response 200 
      if ev
          assert_nil(response.body.index(/.*?#{location}.*?destroyed.*/))
          assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
        else
          assert_nil(response.body.index(/.*?#{location}.*?destroyed.*/))
          assert_raise(ActiveRecord::RecordNotFound) { Message.find(id) }
      end
      receiver_1_headers
      post '/events/fifo', nil, @headers # created event
      assert_response 200 
      if ev
          assert(response.body.index(/.*?#{location}.*?created.*/))
          assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
        else
          assert_nil(response.body.index(/.*?#{location}.*?created.*/))
          assert_raise(ActiveRecord::RecordNotFound) { Message.find(id) }
      end
      receiver_1_headers
      post '/events/fifo', nil, @headers # destroyed event
      assert_response 200 
      if ev
          assert(response.body.index(/.*?#{location}.*?destroyed.*/))
        else
          assert_nil(response.body.index(/.*?#{location}.*?destroyed.*/))
      end
      assert_raise(ActiveRecord::RecordNotFound) { Message.find(id) }
    end
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.events=true;r.save!
    p.call(true)
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.postroute=false;r.save!
    p.call(true)
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.events=false;r.save!
    p.call(false)
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.postroute=true;r.save!
    p.call(false)
  end

  # events true
  # postrouted false
  # community_selfrouting false
  #
  # 1.0 Delete exercise through non owner
  #  1.1 Test index 
  def test_delete_as_non_owner
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.events=true;r.save!
    #p.call(true)
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.postroute=false;r.save!
    #p.call(true)
      sender2_headers
      @participant.community_selfrouting=false;@participant.save!
      location = ""
      post '/numlab/exercises', BODY_DATA, @headers
      assert_response 201
      location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
      id = location.sub(/.*\/(.*)$/,'\1').to_i
      sender2_headers
      get '/numlab/'+location, nil, @headers
      assert_response 200
      assert response.body.index(BODY_DATA)
      assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
      assert !Message.find(id).removed
      receiver_1_headers
      delete '/numlab/'+location, nil, @headers
      assert_response 404
      assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
      assert !Message.find(id).removed
      receiver_2_headers
      delete '/numlab/'+location, nil, @headers
      assert_response 200
      assert response.body.index(BODY_DATA)
      assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
      assert !Message.find(id).removed
      receiver_3_headers
      delete '/numlab/'+location, nil, @headers
      assert_response 200
      assert response.body.index(BODY_DATA)
      assert_nothing_raised(ActiveRecord::RecordNotFound) { Message.find(id) }
      assert Message.find(id).removed
  end
end
