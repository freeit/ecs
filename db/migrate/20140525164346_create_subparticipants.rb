# Copyright (C) 2014 Heiko Bernloehr (FreeIT.de).
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

class CreateSubparticipants < ActiveRecord::Migration
  def self.up
    create_table :subparticipants do |t|
      t.integer :participant_id
      t.integer :parent_id
      t.string :realm

      t.timestamps
    end
  end

  def self.down
    drop_table :subparticipants
  end
end
