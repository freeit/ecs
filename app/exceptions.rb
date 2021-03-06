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


module Ecs
  class DestroyQueueException < StandardError; end
  class AuthenticationException < StandardError; end
  class AuthorizationException < StandardError; end
  class InvalidMessageException < StandardError; end
  class InvalidRessourceUriException < StandardError; end
  class InvalidMimetypeException < StandardError; end
  class OuttimedAuthsException < StandardError; end
  class MissingReceiverHeaderException < StandardError; end
  class NoReceiverOfMessageException < StandardError; end
end
