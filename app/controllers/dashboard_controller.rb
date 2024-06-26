class DashboardController < ApplicationController
  def index
    @employees = Employee.all
  end
end
