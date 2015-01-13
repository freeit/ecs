class LoggingObserver < ActiveRecord::Observer
  observe Event

  def after_create(model)
    case model
      when Event
        msgpath= "#{model.message.ressource.namespace}/#{model.message.ressource.ressource}/#{model.message.id}"
        evreceiver_pid= model.participant.id
        evreceiver_mid= (Membership.receiver(evreceiver_pid, model.message.id)).id
        evtype= model.ev_type.name
        model.logger.info("**#{model.message.ressource.namespace}** Event: Type:#{evtype} -- MsgPath:#{msgpath} -- ReceiverPid:#{evreceiver_pid} -- ReceiverMid:#{evreceiver_mid}")
    end
  end

end
