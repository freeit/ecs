class ConfigsController < ApplicationController

  require 'json/add/rails'

  before_filter :authentication
  before_filter :add_cookie_header # only for anonymous participants

  def initialize
    super
  end

  def index
    config_render
  end

  def create
    unless Mime::Type.lookup(request.headers["CONTENT_TYPE"]) =~ "application/json"
      raise Ecs::InvalidMimetypeException, "Please provide \"Content-Type:\" header. Data format has to be in JSON (application/json)"
    end

    config= ActiveSupport::JSON.decode request.raw_post

    if config["participant_events"] == true
      @participant.events_= true
    else
      @participant.events_= false
    end unless config["participant_events"].nil?

    if config["selfrouting"] == true
      @participant.community_selfrouting= true
    else
      @participant.community_selfrouting= false
    end unless config["selfrouting"].nil?

    @participant.save!
    config_render
  #rescue ActiveSupport::OkJson::Error
  rescue Ecs::InvalidMimetypeException
    raise
  rescue ActiveRecord::RecordInvalid
    raise Ecs::InvalidMessageException, "Data could not be saved (ConfigsController#create)."
  rescue StandardError
    raise Ecs::InvalidMessageException, "You have provided invalid JSON data (ConfigsController#create)."
  end

private

  def config_render
    config = nil
    config_txt = ""
    res_ev={};Ressource.all.each {|r| res_ev["/#{r.namespace}/#{r.ressource}"] = r.events}
    config= \
      { 
        :participant_events => @participant.events?,
        :resource_events => res_ev,
        :selfrouting => @participant.community_selfrouting
      }
    respond_to do |format|
      format.json { render :json  => JSON.pretty_generate(config) + "\r\n" }
      format.xml  { render :xml   => config }
    end
  end

end
