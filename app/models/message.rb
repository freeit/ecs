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


class Message < ActiveRecord::Base

  require 'exceptions'
  require 'json/add/rails'

  has_many :memberships, :through => :membership_messages
  has_many :membership_messages, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :community_messages, :dependent => :destroy
  has_many :communities, :through => :community_messages
  has_one  :auth, :dependent => :destroy
  belongs_to :ressource

  named_scope :for_participant_receiver, lambda {|participant| {
    :joins => {:membership_messages => {:membership => :participant}},
    :order => "id ASC",
    :conditions => {:participants => {:id => participant.id}}}}

  named_scope :for_participant_sender, lambda {|participant| {
    :order => "id ASC",
    :conditions => {:sender => participant.id}}}

  named_scope :for_not_removed, lambda { {
    :order => "id ASC",
    :conditions => {:removed => false}}}

  named_scope :for_resource, lambda {|namespace, name| {
    :joins => :ressource,
    :order => "id ASC",
    :conditions => {:ressources => {:namespace => namespace, :ressource => name}}}}

  def self.create__(request, app_namespace, ressource_name, participant)
    transaction do
      message = create! do |arm|
        create_update_helper(arm, request, app_namespace, ressource_name, participant.id) 
      end
      MembershipMessage.extract_x_ecs_receiver_communities(request.headers["X-EcsReceiverCommunities"]).each do |cid|
        message.communities << Community.find(cid)
      end
      MembershipMessage.populate_jointable(message,
                                           request.headers["X-EcsReceiverMemberships"],
                                           request.headers["X-EcsReceiverCommunities"],
                                           participant)
      Participant.for_message(message).uniq.each do|p|
        Event.make(:event_type_name => EvType.find(1).name, :participant => p, :message => message)
      end if message.ressource.events
      if app_namespace == 'sys' and ressource_name == 'auths'
        message.post_create_auths_resource(participant)
      end
      message
    end
  rescue ActiveRecord::RecordInvalid
    raise Ecs::InvalidMessageException, $!.to_s
  end


  def validate
    if content_type.blank? then
      errors.add_to_base("*** You must povide a \"Content-Type\" header. ")
    end
    if body.blank? then
      errors.add_to_base("*** You have to provide a \"http body\". *** ")
    end
    if sender.blank? then
      errors.add_to_base("*** There is no \"sender\"; this is a fatal error; please report this to ecs@freeit.de. *** ")
    end
  end 

  # return first messages from fifo/lifo queue
  def self.fifo_lifo_rest(namespace, ressource, participant_id, options={:queue_type => :fifo})
    find(:first, :readonly => false, 
      :joins => [:ressource, { :membership_messages => { :membership => :participant } }], 
      :conditions => { :participants => { :id => participant_id },
                       :ressources => { :namespace => namespace, :ressource => ressource } },
      :order => :messages.to_s+".id #{(options[:queue_type]==:fifo)?'ASC':'DESC'}")
  end
 
  # update a message
  def self.update_rest(record, request, app_namespace, ressource_name, participant_id) 
    transaction do
      create_update_helper(record, request, app_namespace, ressource_name, participant_id)
      record.save!
    end
  rescue ActiveRecord::RecordInvalid
    raise Ecs::InvalidMessageException, $!.to_s
  end

  # get a record  out of the message table
  def self.get_record(msg_id, app_namespace, ressource_name)
    outdated_auth_token = nil
    ressource = Ressource.find_by_namespace_and_ressource(app_namespace, ressource_name)
    raise(Ecs::InvalidRessourceUriException, "*** ressource uri error ***") unless ressource
    if app_namespace == 'sys' and ressource_name == 'auths'
      # processing a auths resource
      if msg_id =~ /\D/
        # asking a one touch token with the hash key
        auth = Auth.find_by_one_touch_hash(msg_id)
        if auth
          record = auth.message
        else
          raise ActiveRecord::RecordNotFound, "Invalid auths hash"
        end
      else
        unless record = find_by_id_and_ressource_id(msg_id.to_i, ressource.id)
          raise ActiveRecord::RecordNotFound, "Invalid auths id"
        end
      end
    else
      record = find_by_id_and_ressource_id(msg_id.to_i, ressource.id)
    end
    if !record or record.removed
      raise ActiveRecord::RecordNotFound, "Invalid resource id"
    else
      [record, outdated_auth_token]
    end
  end

  def test_auths_validation_window
    b = JSON.parse(body)
    sov = Time.parse(b["sov"]) 
    eov = Time.parse(b["eov"]) 
    if sov > Time.now or eov < Time.now
      false
    else
      true
    end
  end


  def self.filter(action_name, app_namespace, ressource_name, record, params)
    d="filter/#{app_namespace}/#{ressource_name}/#{action_name}/*"
    filters=Dir[d].collect{|f| File.directory?(f) ? f : nil}.compact
    return if filters.empty?
    FILTER_API.params= params
    FILTER_API.record= record
    filters.sort!
    filters.each do |f|
      files= Dir[f+'/*.rb']
      next if files.empty?
      EcsFilter.constants.each {|c| EcsFilter.instance_eval { remove_const c.to_sym } }
      files.each do |e|
        EcsFilter.module_eval IO.read(e)
      end
      eval "EcsFilter::Filter.start"
    end
  rescue Exception
    logger.error "Filter Exception: "+$!.class.to_s+": "+$!.backtrace[0]
    logger.error "Filter Exception: "+$!.message
  end

  # Request body has to be in json format.
  # Preprocess request body if it's a /sys/auths resource.
  # Generate a one touch token (hash)
  def post_create_auths_resource(participant)
    ttl = 60.seconds
    unless Mime::Type.lookup(self.content_type).to_sym == :json
      raise Ecs::InvalidMimetypeException, "Body format has to be in JSON"
    end
    begin
      b = JSON.parse(self.body)
    rescue JSON::ParserError
      raise Ecs::InvalidMessageException, "Invalid JSON body"
    end
    bks = b.keys
    unless bks.include?("url")
      raise Ecs::InvalidMessageException, "Missing url key"
    end
    #msg_id = URI.split(b["url"])[5][1..-1].sub(/[^\/]*\/[^\/]*\/(.*)/, '\1').to_i
    #begin
    #  Message.find(msg_id)
    #rescue ActiveRecord::RecordNotFound
    #  raise Ecs::InvalidMessageException, $!.to_s
    #end
    case
      when (!bks.include?("sov") and !bks.include?("eov"))
        b["sov"] = Time.now.xmlschema
        b["eov"] = (Time.now + ttl).xmlschema
      when (bks.include?("sov") and !bks.include?("eov"))
        b["eov"] = (Time.parse(b["sov"]) + ttl).xmlschema
      when (!bks.include?("sov") and bks.include?("eov"))
        if Time.parse(b["eov"]) < Time.now
          raise Ecs::InvalidMessageException, 'eov time is younger then current time'
        end
        b["sov"] = Time.now.xmlschema
      when (bks.include?("sov") and bks.include?("eov"))
        if (Time.parse(b["eov"]) < Time.now) or (Time.parse(b["eov"]) < Time.parse(b["sov"]))
          raise Ecs::InvalidMessageException, 'invalid times either in sov or eov'
        end
    end 
    b["abbr"] = participant.organization.abrev
    one_touch_token_hash = Digest::SHA1.hexdigest(rand.to_s+Time.now.to_s)
    b["hash"] = one_touch_token_hash
    self.body = JSON.pretty_generate(b)
    self.auth = Auth.new :one_touch_hash => one_touch_token_hash
    save!
    self
  end

  # If the record has zero relations to memberships and is not tagged for
  # postrouting it will be deleted.
  def destroy_unlinked_and_not_postrouted
    destroy_or_tag_as_removed if membership_messages.blank? and !ressource.postroute
  end
    

  # Delete a message and send appropriate events. It will only be "fully"
  # deleted when there are no references from any events otherwise it will be
  # tagged as deleted.
  def destroy_
    participants = Participant.for_message(self).uniq
    participants.each do |participant| 
      Event.make(:event_type_name => EvType.find(2).name, :participant => participant, :message => self)
    end if ressource.events
    MembershipMessage.delete_relations(self)
    destroy_or_tag_as_removed
  end

  def outtimed_auths_resource_by_non_owner?(app_namespace, resource_name, memberships, participant)
    app_namespace  == 'sys' and
    resource_name == 'auths' and
    !memberships.empty? and
    !participant.sender?(self) and
    !test_auths_validation_window
  end


  def valid_auths_resource_fetched_by_non_owner?(app_namespace, resource_name, memberships, participant)
    app_namespace  == 'sys' and
    resource_name == 'auths' and
    !memberships.empty? and
    !participant.sender?(@record) and
    test_auths_validation_window
  end

  def valid_no_auths_resource_fetched_by_non_owner?(app_namespace, resource_name, memberships, participant)
    app_namespace  != 'sys' and
    ressource_name != 'auths' and
    !memberships.empty? and
    !participant.sender?(@record)
  end

private

  # Helper function for create and update 
  # ttl:integer livetime of message in seconds 
  def self.create_update_helper(arm, request, app_namespace, ressource_name, participant_id)
    ressource = Ressource.find_by_namespace_and_ressource(app_namespace, ressource_name)
    raise(Ecs::InvalidRessourceUriException, "*** ressource uri error ***") unless ressource
    arm.ressource_id = ressource.id
    arm.content_type = request.headers["CONTENT_TYPE"]
    arm.sender = participant_id
    arm.body = request.raw_post
  end

  # Deletes the message if there are no references from events otherwise it
  # will be tagged as deleted.
  def destroy_or_tag_as_removed
    if self.events.blank?
      destroy
    else
      self.removed = true
      save!
    end
  end

end
