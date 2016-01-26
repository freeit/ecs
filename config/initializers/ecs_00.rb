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


# Filter-Namespace
module EcsFilter
end

class FilterApi
  attr_accessor :params, :record
end

FILTER_API=FilterApi.new

# read configuration data
require 'yaml'

begin
  ECS_CONFIG = YAML::load_stream(File.open(Rails.root.join('config','ecs_config.yml')))[0]
rescue Exception
  Rails.logger.fatal "Reading #{Rails.root.join('config','ecs_config.yml')}"
end

ECS_CONFIG["participants"]["allow_anonymous"] = false unless defined? ECS_CONFIG["participants"]["allow_anonymous"]
ECS_CONFIG["participants"]["allow_events"] = true unless defined? ECS_CONFIG["participants"]["allow_events"]
ECS_CONFIG["admin"]["confirm_actions"] = true unless defined? ECS_CONFIG["admin"]["confirm_actions"]
