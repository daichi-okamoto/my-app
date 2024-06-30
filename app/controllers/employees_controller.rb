class EmployeesController < ApplicationController
  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params.merge(user_id: current_user.id))
    if @employee.save
      redirect_to dashboard_index_path, success: 'スタッフが登録されました'
    else
      flash.now[:danger] = 'スタッフの登録に失敗しました'
      render :new, status: :unprocessable_entity
    end
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
    @employee = Employee.find(params[:id])
    if @employee.update(employee_params)
      redirect_to dashboard_index_path, success: 'スタッフが更新されました'
    else
      flash.now[:danger] = 'スタッフの更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end 
  
  def destroy
    @employee = Employee.find(params[:id])
    @employee.destroy
    redirect_to dashboard_index_path, status: :see_other, success: 'スタッフが削除されました'
  end

  private

  def employee_params
    params.require(:employee).permit(:name, :employee_type, :user_id, :early_shift, :day_shift, :late_shift, :night_shift)
  end
end
