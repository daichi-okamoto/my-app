class EmployeesController < ApplicationController
  def new
    
  end

  def index
    @employees = Employee.all
  end

  def show
    @employee = Employee.find(params[:id])
  end

  def edit
    @employee = Employee.find(params[:id])
  end

  def update
  end

  def destroy
  end
end
