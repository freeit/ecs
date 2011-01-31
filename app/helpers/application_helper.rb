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


# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # return a collection of all communities with an empty one appended.
  def setup_community_collection
    return Community.find(:all) << Community.new
  end

  # returns the maximum line width of a text with "\r\n" lineendings.
  def max_text_width(text)
    text.split(/\r\n/).map {|t| t.length}.max
  end

end
