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
    index_querystring_list
    @list.each do |li| 
      @body << @ressource_name << "/" << li.id.to_s << "\n"
    end unless @list.empty?
    index_render
  end

  def show
    @memberships = Membership.receiver(@participant.id, @record.id)
    case
    when @record.outtimed_auths_resource_by_non_owner?(@app_namespace, @resource_name, @participant)
      raise Ecs::OuttimedAuthsException, 'Authorization token outtimed'
    when (!@memberships.empty? or @participant.sender?(@record))
      Message.filter(__method__, @app_namespace, @ressource_name, @record, params)
      @body = @record.body 
      show_render
    else
      raise Ecs::AuthorizationException, 
            "You are not allowed to access this resource, " +
            "because you are not the original sender or a receiver."
    end
  end


  # Create and save a new message. Then render "Created 201" response.
  # - todo: exceptions for: create, constantize
  def create
    @record= Message.create__(request, @app_namespace, @ressource_name, @participant)
    @body = @record.body
    create_render
  end

  def update
    @record.update__(request, @app_namespace, @ressource_name, @participant)
    update_render
  end

  def destroy
    case
    when @record.outtimed_auths_resource_by_non_owner?(@app_namespace, @resource_name, @participant)
      @record.destroy_as_receiver(@participant)
      raise Ecs::OuttimedAuthsException, 'Authorization token outtimed'
    when @participant.sender?(@record)
      @record.destroy_as_sender
    else
      @record.destroy_as_receiver(@participant)
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

  def details
    details = nil
    no_data_to_render = false
    if params["id"]
      # member subresource
      details = member_subresource_details(params["id"])
      if !details[:receivers] then  no_data_to_render = true end
    else
      index_querystring_list
      # collection subresource
      details ||= []
      @list.each do |li| 
        details << member_subresource_details(li.id)
      end unless @list.empty?
      if details.empty? then  no_data_to_render = true end
    end
    if no_data_to_render
      render :text => "", :content_type => "application/json", :layout => false
    else
      respond_to do |format|
        format.json  { render :json  => JSON.pretty_generate(details) }
        format.xml   { render :xml   => details }
      end
    end
  end

protected

  def member_subresource_details(record_id)
    get_record(record_id)
    if @participant.sender?(@record) or @participant.receiver?(@record)
      receivers=[]
      senders=[]
      Membership.receivers(@record.id).each do |recv|
        receivers << { :pid => recv.participant.id, :mid => recv.id, :cid => recv.community_id,
                       :itsyou => recv.participant_id == @participant.id }
        senders << { :mid => Membership.find_by_participant_id_and_community_id(@record.sender, recv.community_id).id }
      end
      content_type = @record.content_type
      url = @ressource_name + "/" + record_id.to_s
      { :receivers => receivers,
        :senders => senders,
        :content_type => content_type,
        :url => url,
        :owner => { :itsyou => @participant.id == @record.sender,
                    :pid => @record.sender }
      }
    else
      raise Ecs::AuthorizationException, 
            "You are not allowed to access this resource, " +
            "because you are not the original sender or a receiver."
    end
  end

  def index_querystring_list
    header_querystrings = request.headers["X-EcsQueryStrings"]
    if header_querystrings
      hqs = header_querystrings.split(",").map{|s| s.strip}.map{|s| s.split("=").map{|s| s.strip}}
      sender = (m=hqs.assoc("sender")) ? m[1] : nil
      receiver = (m=hqs.assoc("receiver")) ? m[1] : nil
      all = (m=hqs.assoc("all")) ? m[1] : nil
    end
    sender ||= params["sender"] ? params["sender"] : nil
    receiver ||= params["receiver"] ? params["receiver"] : nil
    all ||= params["all"] ? params["all"] : nil
    case
    when sender == "true"
      @list = Message.for_participant_sender(@participant).for_resource(@app_namespace,@ressource_name).for_not_removed.uniq
    when receiver == "true"
      @list = Message.for_participant_receiver(@participant).for_resource(@app_namespace,@ressource_name).for_not_removed.uniq
    when all == "true"
      list1 = Message.for_participant_sender(@participant).for_resource(@app_namespace,@ressource_name).for_not_removed
      list2 = Message.for_participant_receiver(@participant).for_resource(@app_namespace,@ressource_name).for_not_removed
      @list = list1.concat(list2).uniq
    else
      @list = Message.for_participant_receiver(@participant).for_resource(@app_namespace,@ressource_name).for_not_removed.uniq
    end
  end

  def queue(queue_options = {:queue_type => :fifo})
    begin
      Message.transaction do
        # returned record holds a lock (pessimistic locking)
        @record = Message.fifo_lifo_rest(@app_namespace, @ressource_name,@participant.id, queue_options)
        if @record
          @memberships = Membership.receiver(@participant.id, @record.id)
          @body = @record.body 
          if request.post?
            if @record
              @record.destroy_as_receiver(@participant)
            else
              raise ActiveRecord::RecordNotFound
            end
          end
          show_render
        else
          empty_render
        end
      end
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotFound => error
      logger.info "Concurrent access at queue resource"
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

  # get a record  out of the message table
  def get_record(record_id = params["id"], app_namespace=@app_namespace, ressource_name=@ressource_name)
    @record, @outdated_auth_token = Message.get_record(record_id, app_namespace, ressource_name)
  end
    
  def empty_render
    render :text => "", :content_type => "application/json"
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
      x_ecs_sender << Membership.find_by_participant_id_and_community_id(Participant.find(@record.sender).id, memb.community.id).id.to_s 
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
      render :text => @body, :layout => false, :status => 200, :content_type => Mime::Type.lookup(@record.content_type)
    end
  end

  def create_render
    location = request.protocol + request.host
    location += request.headers["SCRIPT_NAME"] if request.headers.has_key?("SCRIPT_NAME")
    location += request.path.gsub(/\/*$/,'') + "/" + @record.id.to_s
    if @app_namespace == 'sys' and @ressource_name == 'auths'
      render :text => @body, :layout => false, :status => 201, :location => location, :content_type => Mime::Type.lookup_by_extension("json")
    else
      render :text => "", :layout => false, :status => 201, :location => location, :content_type => Mime::Type.lookup(@record.content_type)
    end
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
