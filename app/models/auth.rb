class Auth < ActiveRecord::Base
  belongs_to :message 

  #named_scope :hash, lambda {|hash| {
  #  :joins => {:membership_messages => {:membership => :participant}},
  #  :order => "id ASC",
  #  :conditions => {:participants => {:id => participant.id}}}}
end
