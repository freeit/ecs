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


class MessagesController < ApplicationController

  before_filter :late_initialize
  before_filter :authentication
  before_filter :add_cookie_header
  before_filter :get_record, :only => [:show, :update, :destroy]
  after_filter  :touch_participant_ttl

  def initialize
    super
  end

  def index
    @list = Message.index_rest(@app_namespace, @ressource_name, @participant)
    @list.each do |li| 
      @body << @ressource_name << "/" << li.id.to_s << "\n"
    end unless @list.empty?
    # render only if ":contoller => :messages" in routes.rb file
    # otherwise call render out of the namespace specific controller.
    index_render
  end

  def show
    if !(@memberships = Membership.receiver(@participant.id, @record.id)).empty? or sender?(@participant, @record)
      Message.filter(__method__, @app_namespace, @ressource_name, @record, params)
      @body = @record.body 
      show_render
    else
      raise Ecs::AuthorizationException, 
            "You are not allowed to access this resource, because you are not the original sender or a receiver."
    end
  end


  # Create and save a new message. Then render "Created 201" response.
  # - todo: exceptions for: create, constantize
  def create
    Message.transaction do
      Message.filter(__method__, @app_namespace, @ressource_name, @record, params)
      @record = Message.create_rest(request, @app_namespace, @ressource_name, @participant.id)
      logger.info "@record="+@record.inspect
      MembershipMessage.populate_jointable(@record,
                                           request.headers["X-EcsReceiverMemberships"],
                                           request.headers["X-EcsReceiverCommunities"],
                                           @participant)
      participants = Participant.for_message(@record).uniq
      participants.each do |participant| 
        Event.make(:event_type_name => EvType.find(1).name, :participant => participant, :message => @record)
      end if @record.ressource.events
    end
    create_render
  end

  def update
    raise(Ecs::AuthorizationException, "You are not the original sender of the message.") unless sender?(@participant,@record)
    Message.transaction do
      Message.update_rest(@record, request, @app_namespace, @ressource_name, @participant.id)
      MembershipMessage.de_populate_jointable(@record)
      MembershipMessage.populate_jointable(@record,
                                           request.headers["X-EcsReceiverMemberships"],
                                           request.headers["X-EcsReceiverCommunities"],
                                           @participant)
      # TODO: if there are only the headers X-EcsReceiverMemberships and
      # X-EcsReceiverCommunities are updated, then we have to generate events only
      # for these new receivers.
      participants = Participant.for_message(@record).uniq
      participants.each do |participant| 
        Event.make(:event_type_name => EvType.find(3).name, :participant => participant, :message => @record)
      end if @record.ressource.events
    end
    update_render
  end

  def destroy
    if sender?(@participant,@record)
      participants = Participant.for_message(@record).uniq
      participants.each do |participant| 
        Event.make(:event_type_name => EvType.find(2).name, :participant => participant, :message => @record)
      end if @record.ressource.events
      MembershipMessage.delete_relations(@record)
      @record.destroy_ressource
    else
      @memberships = Membership.receiver(@participant.id, @record.id)
      raise ActiveRecord::RecordNotFound if @memberships.empty?
      MembershipMessage.delete_relations(@record, @memberships)
      Message.destroy_unlinked_and_not_postrouted(@record)
    end
    @body = @record.body
    show_render
  end

  def fifo
    queue(:queue_type => :fifo)
  end

  def lifo
    queue(:queue_type => :lifo)
  end

protected

  def queue(queue_options = {:queue_type => :fifo})
    max_tries = 5
    begin
      MembershipMessage.transaction do
        @record = Message.fifo_lifo_rest(@app_namespace, @ressource_name,@participant.id, queue_options)
        if @record
          @memberships = Membership.receiver(@participant.id, @record.id)
          @body = @record.body 
          if request.post?
            MembershipMessage.delete_relations(@record, @memberships)
            Message.destroy_unlinked_and_not_postrouted(@record)
          end
          show_render
        else
          index_render
        end
      end
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotFound => error
      logger.info "**** Concurrent access at queue ressource (max_tries=#{max_tries})."
      max_tries-= 1
      retry unless max_tries <= 0
      raise
    end
  end


  # inititialize instance variables dependent from request object
  def late_initialize
    @app_namespace= request.path.sub(/^\//,'').sub(/\/.*/,'')
    @ressource_name= $&.sub(/\//,'').sub(/\/.*/,'')
    #@ar_model_name= "#{@app_namespace}_#{@ressource_name}".pluralize.classify
    #@ar_model= @ar_model_name.constantize
  end


  # returns a membership of the relation between a participant and a community
  # otherwise returns nil.
  def get_membership_from_participant_and_community(participant, community)
    (participant.memberships & community.memberships)[0]
  end


  # test if the calling participant is the initial sender of the message in question.
  def sender?(participant, message)
    return true if message.sender == participant.id
    false
  end

  # get a record  out of the message table
  def get_record
    @record = Message.get_record(params[:id], @app_namespace, @ressource_name)
  end
    
  def index_render
    render :text => @body, :content_type => "text/uri-list"
  end

  def show_render
    #expires_in 3.hours, 'max-stale' => 5.hours, :public => true
    headers["Cache-Control"] = "private, max-age=5"
    x_ecs_receiver_communities= ""
    x_ecs_sender= ""
    @memberships.each do |memb| 
      x_ecs_receiver_communities << memb.community.id.to_s 
      x_ecs_sender << get_membership_from_participant_and_community(Participant.find(@record.sender), memb.community).id.to_s 
      unless @memberships.last == memb
        x_ecs_receiver_communities << ","
        x_ecs_sender << "," 
      end
    end unless @memberships.blank?
    headers["X-EcsReceiverCommunities"]= x_ecs_receiver_communities unless x_ecs_receiver_communities.blank?
    headers["X-EcsSender"]= x_ecs_sender unless x_ecs_sender.blank?
    if stale?(:etag => @record, :last_modified => @record.updated_at.utc, 
              :x_ecs_receiver_communities => x_ecs_receiver_communities, 
              :x_ecs_sender => x_ecs_sender)
      render :text => @body, :layout => false, :status => 200, :content_type => @record.content_type
    end
  end

  def create_render
    location = request.protocol + request.host
    location += request.headers["SCRIPT_NAME"] if request.headers.has_key?("SCRIPT_NAME")
    location += request.path.gsub(/\/*$/,'') + "/" + @record.id.to_s
    render :text => "", :layout => false, :status => 201,
           :location => location
  end

  def update_render
    location = request.protocol + request.host
    location += request.headers["SCRIPT_NAME"] if request.headers.has_key?("SCRIPT_NAME")
    location += request.path.gsub(/\/*$/,'')
    render :text => "", :layout => false, :status => 200,
           :location => location
  end

  def destroy_render
    render :nothing => true, :layout => false, :status => 200,
           :content_type => "application/json"
  end

  # this is a custom fresh_when function, which is called by stale?
  # see http://www.themomorohoax.com/2009/01/07/using-stale-with-rails-to-return-304-not-modified
  def fresh_when(options)
    options.assert_valid_keys(:etag, :last_modified, :x_ecs_receiver_communities, :x_ecs_sender)
  
    response.etag          = options[:etag]          if options[:etag]
    response.last_modified = options[:last_modified] if options[:last_modified]
    response.headers["X-EcsReceiverCommunities"] = options[:x_ecs_receiver_communities] unless options[:x_ecs_receiver_communities].blank?
    response.headers["X-EcsSender"] = options[:x_ecs_sender] unless options[:x_ecs_sender].blank?
  
    if request.fresh?(response)
      head :not_modified
    end
  end

end
