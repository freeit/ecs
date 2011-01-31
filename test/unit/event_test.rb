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

class EventTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "generate new created event" do
    Event.delete_all
    ec = Event.all.count
    ev = nil
    assert_nothing_raised(Exception) do
      ev = Event.make(:event_type_name => ev_types(:created).name, :membership_message => MembershipMessage.find(1))
    end

    assert_nothing_raised(ActiveRecord::RecordNotFound) { ev = Event.find(ev.id) }
    assert_equal(1,Event.all.count)

    assert_equal(participants(:ilias_stgt).id, ev.participant_id)
    assert_equal(messages(:numlab_ex1).id, ev.message_id)
    assert_equal(ev_types(:created).id, ev.ev_type_id)
  end

  test "participant deletion" do
    Event.delete_all
    ev = nil
    assert_nothing_raised(Exception) do
      ev = Event.make(:event_type_name => ev_types(:created).name, :membership_message => MembershipMessage.find(1))
    end

    assert_nothing_raised(Exception) { participants(:ilias_stgt).destroy }
    assert_raise(ActiveRecord::RecordNotFound) { Event.find(ev.id) } # event has to be gone (removed)
    assert_equal(0,Event.all.count) # event has to be gone (removed)
  end

end
