class AddPtypeToParticipants < ActiveRecord::Migration
  def self.up
    add_column :participants, :ptype, :string
    assign_participant_type
  end

  def self.down
    remove_column :participants, :ptype
  end

private

  def self.assign_participant_type
    Participant.all.each do |p|
      case
        when p.mainparticipant? then  p.ptype= Participant::TYPE[:main]
        when p.subparticipant? then  p.ptype= Participant::TYPE[:sub]
        when p.anonymousparticipant? then  p.ptype= Participant::TYPE[:anonym]
      end
      p.save!
    end
  end
end
