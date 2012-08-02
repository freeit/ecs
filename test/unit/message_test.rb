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

# request stub
class TestRequest
  attr_accessor :headers, :raw_post
  def initialize(h,rp); @headers, @raw_post = h, rp; end
end

class MessageTest < ActiveSupport::TestCase
  test "named_scope__for_participant_receiver" do
    m= Message.for_participant_receiver participants(:ilias_stgt)
    assert_equal 2,m.length
    assert m.include?(messages(:numlab_ex1))
    assert m.include?(messages(:numlab_ulm_ex1))
  end

  # Change receivers community SUV (:ilias_stgt, :ilias_ulm) to :numlab_teacher
  # and :ilias_ulm 
  # Note: In the fixtures :ilias_stgt is configured as a receiver because it is
  # in the SUV community. This is not correct because :ilias_stgt doesn't set
  # community_selfrouting, but it's history.
  test "update_receivers" do
    headers={
      "X-EcsReceiverMemberships" => "7,2",
      "CONTENT_TYPE" => "text/plain"
      }
    raw_post= "hallo ich war da"
    request= TestRequest.new(headers, raw_post)
    assert_nothing_raised do
      messages(:numlab_ex1).update__(request, "numlab", "exercises", participants(:ilias_stgt))
    end
    # :numlab_teacher is a new receiver and gets an created event
    assert Participant.for_message(messages(:numlab_ex1)).uniq.include?(participants(:numlab_teacher))
    assert Event.find_by_participant_id_and_ev_type_id(participants(:numlab_teacher).id,EvType.find_by_name("created"))
    # :ilias_stgt isn't a receiver anymore and gets an destroyed event (:ilias_stgt was a receiver through fixture)
    assert !Participant.for_message(messages(:numlab_ex1)).uniq.include?(participants(:ilias_stgt))
    assert Event.find_by_participant_id_and_ev_type_id(participants(:ilias_stgt).id,EvType.find_by_name("destroyed"))
    # :ilias_ulm is still a receiver and gets an updated event
    assert Participant.for_message(messages(:numlab_ex1)).uniq.include?(participants(:ilias_ulm))
    assert Event.find_by_participant_id_and_ev_type_id(participants(:ilias_ulm).id,EvType.find_by_name("updated"))
    # number of receivers have to be two
    assert_equal 2, Participant.for_message(messages(:numlab_ex1)).uniq.length
  end  
end


