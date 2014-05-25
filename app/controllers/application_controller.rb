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


# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class ApplicationController < ActionController::Base

  require 'exceptions'
  require 'pp'
  require 'json/add/rails'

  #rescue_from Exception, :with => :rescue_body_500
  rescue_from Ecs::InvalidMessageException, :with => :rescue_body_400
  rescue_from Ecs::MissingReceiverHeaderException, :with => :rescue_body_400
  rescue_from Ecs::AuthenticationException, :with => :rescue_body_401
  rescue_from Ecs::AuthorizationException, :with => :rescue_body_403
  rescue_from Ecs::InvalidRessourceUriException, :with => :rescue_body_404
  rescue_from ActiveRecord::RecordNotFound, :with => :rescue_body_404
  rescue_from ActionController::RoutingError , :with => :rescue_body_404
  rescue_from Ecs::NoReceiverOfMessageException, :with => :rescue_body_404
  rescue_from Ecs::OuttimedAuthsException, :with => :rescue_body_409
  rescue_from ActiveRecord::StaleObjectError, :with => :rescue_body_409
  rescue_from ActiveRecord::StatementInvalid, :with => :rescue_body_415
  rescue_from Ecs::InvalidMimetypeException, :with => :rescue_body_415

  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # session :on

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  #

  def initialize
    super
    #@ar_model_name = nil
    #@ar_model = nil
    @list = nil
    @record = nil
    @app_namespace = nil
    @ressource_name = nil
    @ressource_path = nil
    @body = ""
    @participant = nil
    @memberships = nil
    @cookie = nil
    @outdated_auth_token = nil
  end

protected

  def authentication
    if ECS_CONFIG["participants"]["allow_anonymous"]
      # new anonymous participant
      if new_anonymous_participant?
        @participant, @cookie = Participant.generate_anonymous_participant
        logger.info "Cookie (new anonymous participant): #{@cookie} -- Participant-ID: #{@participant.id}"
        return @participant
      end
      # anonymous participants
      if (participant= anonymous_participant)
        logger.info "Cookie: #{@cookie} -- Participant-ID: #{participant.id}"
        return @participant = participant
      end
    end
    # authenticated participants
    auth_id, participant = authenticated_participant
    if participant
      logger.info "X-EcsAuthId: #{auth_id} -- Participant-ID: #{participant.id}"
      return @participant= participant
    end
  end

  def new_anonymous_participant?
    request.headers["X-EcsAuthId"].blank? and request.headers["Cookie"].blank?
  end

  def anonymous_participant
    if !(@cookie = cookies[:ecs_anonymous]).blank?
      if (identity = Identity.find_by_name(@cookie)).blank?
        raise Ecs::AuthenticationException, "No valid identity found for cookie: #{@cookie}"
      elsif (participant = identity.participant).blank?
        raise Ecs::AuthenticationException, "Cookie: #{@cookie}\" is not assigned any participant"
      else
        return participant
      end
    else
      false
    end
  end

  def authenticated_participant
    if (auth_id = request.headers["X-EcsAuthId"]).blank?
      raise Ecs::AuthenticationException, "No \"X-EcsAuthId\" http header"
    elsif (identity = Identity.find_by_name(auth_id)).blank?
      raise Ecs::AuthenticationException, "No \"X-EcsAuthId: #{auth_id}\" identity found"
    elsif (participant = identity.participant).blank?
      raise Ecs::AuthenticationException, "\"X-EcsAuthId: #{auth_id}\" is not assigned any participant"
    else
      return auth_id, participant
    end
  end

  # set the cookie header
  def add_cookie_header
    cookies[:ecs_anonymous] = \
      {
        :value => @cookie, 
        :path => "/", 
        :expires => Participant::TTL.seconds.from_now
      } unless @cookie.blank?
  end

  def touch_participant_ttl
    Participant.touch_ttl(@participant) if @participant.anonymous
  end



  # error pages
  def rescue_body_401
    @http_error= $!
    logger.error $!.to_s
    render :text => "#{$!.to_s}\n", :layout => false, :status => 401
  end

  def rescue_body_500
    @http_error= $!
    logger.error $!.to_s
    render :text => "#{$!.to_s}\n", :layout => false, :status => 500
  end

  def rescue_body_400
    @http_error= $!
    logger.error $!.to_s
    render :text => "#{$!.to_s}\n" , :layout => false, :status => 400
  end
  
  def rescue_body_403
    @http_error= $!
    logger.error $!.to_s
    render :text => "#{$!.to_s}\n" , :layout => false, :status => 403
  end

  def rescue_body_404
    @http_error= $!
    logger.error $!.to_s
    if $!.to_s.blank?
      render :text => "The server does not know the ressource\nor the message queue in question is empty.\n" , :layout => false, :status => 404
    else
      render :text => "#{$!.to_s}\n" , :layout => false, :status => 404
    end
  end

  def rescue_body_409
    @http_error= $!
    logger.error $!.to_s
    render :text => "#{$!.to_s}\n" , :layout => false, :status => 409
  end
  
  def rescue_body_415(controller_binding)
    @http_error= $!
    logger.error $!.to_s
    if $!.to_s.blank?
      render :text => "The format of the client data is not supported by the server.\nIf your format is right please doublecheck the encoding !\nIt has to be UTF8 !\n", :layout => false, :status => 415
    else
      render :text => "#{$!.to_s}\n" , :layout => false, :status => 415
    end

  end
end
