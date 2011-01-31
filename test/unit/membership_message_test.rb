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

class MembershipMessageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  # Only testing for destroy should be sufficient, because updating is
  # implemented as first destroying and recreating the membership_messages
  test "optimistic locking" do
    mm1 = mm2 = nil
    assert_nothing_raised(ActiveRecord::RecordNotFound) { mm1 = MembershipMessage.find(1) }
    assert_nothing_raised(ActiveRecord::RecordNotFound) { mm2 = MembershipMessage.find(1) }
    assert_nothing_raised(Exception) { mm1.destroy }
    assert_raise(ActiveRecord::StaleObjectError) { mm2.destroy }
  end
end
