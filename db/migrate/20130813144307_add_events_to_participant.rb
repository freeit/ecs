class AddEventsToParticipant < ActiveRecord::Migration
  def self.up
    add_column :participants, :events_, :boolean, :default => true
    Participant.all.each do |p|
      p.events_= ECS_CONFIG["participants"]["allow_events"]
      p.save!
    end
  end

  def self.down
    remove_column :participants, :events_
  end
end
