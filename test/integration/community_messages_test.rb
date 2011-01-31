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

class CommunityMessagesTest < ActionController::IntegrationTest
  fixtures :all

  BODY_DATA = "hallole"

  def sender_headers
    @headers ||= {}
    @headers['HTTP_ACCEPT'] = 'text/plain'
    @headers['CONTENT_TYPE'] = 'text/plain'
    @participant = identities(:stgt_id1).participant
    @headers["X-EcsAuthId"] = identities(:stgt_id1).name
    @headers["X-EcsReceiverCommunities"] = communities(:suv).name + ',' + communities(:wuv).name
    @headers["X-EcsReceiverMemberships"] = ""
  end

  def setup
  end

  def test_new_jointable_entries
    sender_headers
    post '/numlab/exercises', BODY_DATA, @headers
    assert_response 201
    mid = URI.split(headers["Location"])[5].sub(/.*\/(.*)/, '\1')
    assert Message.find(mid).communities.map{|c| c.name}.include?(communities(:suv).name)
    assert Message.find(mid).communities.map{|c| c.name}.include?(communities(:wuv).name)
    assert_equal 2, Message.find(mid).communities.length
  end

  def test_if_jointable_entries_will_be_deleted
    r=Ressource.find_by_namespace_and_ressource("numlab","exercises");r.events=false;r.save!
    cm_count = CommunityMessage.all.length
    sender_headers
    post '/numlab/exercises', BODY_DATA, @headers
    assert_equal cm_count+2, CommunityMessage.all.length # addressed to two communities
    location = URI.split(headers["Location"])[5][1..-1].sub(/[^\/]*\/(.*)/, '\1')
    mid = URI.split(headers["Location"])[5].sub(/.*\/(.*)/, '\1')
    sender_headers
    delete '/numlab/'+location, nil, @headers
    assert_response 200
    assert_equal cm_count, CommunityMessage.all.length
  end

end

