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


class AddMonitorToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :lock_version, :integer, :default => 0
    add_column :messages, :monitor, :integer, :default => 0
    #Message.all.each do |m|
    #  m.lock_version = 0
    #  m.monitor = false
    #  m.save
    #end
  end

  def self.down
    remove_column :messages, :monitor
    remove_column :messages, :lock_version
  end
end
