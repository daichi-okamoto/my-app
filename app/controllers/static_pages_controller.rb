class StaticPagesController < ApplicationController
  skip_before_action :require_login
  
  def privacy_policy
  end

  def inquiry
  end
end
