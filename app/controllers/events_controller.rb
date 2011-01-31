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


class EventsController < ApplicationController

  require 'json/add/rails'

  before_filter :authentication
  before_filter :add_cookie_header # only for anonymous participants

  def initialize
    super
  end

  def index
    count = params["count"].blank? ? -1 : params["count"].to_i
    events_render(@participant.id, count)
  end

  def fifo
    max_tries = 5
    begin
      Event.transaction do
        events_render(@participant.id, 1)
      end
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotFound => error
      logger.info "**** Concurrent access at events queue (max_tries=#{max_tries})."
      max_tries-= 1
      retry unless max_tries <= 0
      raise
    end
  end

private

  def events_render(participant_id, count)
    events = []
    events_txt = ""
    Event.for_participant(participant_id,count).each do |event|
      if request.post?
        event.destroy
        # do not destroy message if another reference in events to the message
        # exists or the message is not marked as removed
        unless Event.find_by_message_id(event.message.id) or !event.message.removed
          event.message.destroy
        end
      end
      events <<
        { 
          :ressource => event.message.ressource.namespace + "/" +
                        event.message.ressource.ressource + "/" +
                        event.message.id.to_s,
          :status => event.ev_type.name
        }
    end
    respond_to do |format|
      format.json { render :json  => JSON.pretty_generate(events) }
      format.xml  { render :xml   => events }
      format.text { render :text  => events_render_txt(events) }
    end
  end

  def events_render_txt(events)
    events_txt = ""
    events.each do |event|
      events_txt << event[:ressource] + "   " + event[:status] + "\r\n"
    end
    events_txt
  end

end
