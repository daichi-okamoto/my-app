class ShiftRequestsController < ApplicationController
  before_action :set_common_data, only: [:new, :create]

  def new
    @shift_request = ShiftRequest.new
  end

  def create
    shift_requests_params = shift_request_params[:shift_requests].to_h
    shift_requests = shift_requests_params.map do |employee_id, shifts|
      shifts.map do |date, shift_type|
        next if shift_type.blank?

        ShiftRequest.create(
          employee_id: employee_id,
          date: Date.parse(date),
          shift_type: format_shift_type(shift_type)
        )
      end
    end.flatten.compact

    if shift_requests.any?
      flash[:success] = '勤務希望を保存しました'
      redirect_to new_shift_path(year: params[:shift_request][:year], month: params[:shift_request][:month])
    else
      flash[:danger] = '勤務希望の保存に失敗しました'
      render :new, status: :unprocessable_entity
    end
    
  end

  def destroy
    @shift_request = ShiftRequest.find(params[:id])
    @shift_request.destroy
    redirect_to shift_requests_path
  end

  private

  def shift_request_params
    params.require(:shift_request).permit(:year, :month, shift_requests: {})
  end

  def format_shift_type(shift_type)
    case shift_type
    when 'H' then '早番'
    when 'N' then '日勤'
    when 'O' then '遅番'
    when 'Y' then '夜勤'
    when '⚫️' then '休み'
    else shift_type
    end
  end

  def set_common_data
    @employees = Employee.all
    @shifts = Shift.all.group_by(&:employee_id)
    @shift_requests = ShiftRequest.where(date: @start_date..@end_date)
    set_month_data(params[:year], params[:month])
  end
end
