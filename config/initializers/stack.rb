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


ActionController::Dispatcher.middleware = ActionController::MiddlewareStack.new do |m|
  m.use Rack::Lock
  m.use ActionController::Failsafe
  m.use ActiveRecord::ConnectionAdapters::ConnectionManagement
  m.use ActiveRecord::QueryCache
  m.use Rack::MethodOverride
  m.use Rack::Head
end 


#use Rack::Lock
#use ActionController::Failsafe
#use ActiveRecord::ConnectionAdapters::ConnectionManagement
#use ActiveRecord::QueryCache
#use ActiveRecord::SessionStore, #<Proc:0xf7b75b90@(eval):8>
#use ActionController::ParamsParser
#use Rack::MethodOverride
#use Rack::Head

