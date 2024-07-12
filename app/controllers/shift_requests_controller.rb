class ShiftRequestsController < ApplicationController
  before_action :set_common_data, only: [:new, :create]

  def new
    @shift_request = ShiftRequest.new
  end

  def create
    Rails.logger.debug "Received params: #{params.inspect}"
    shift_requests_params = shift_request_params[:shift_requests].to_h
    memos_params = shift_request_params[:memos].to_h
  
    Rails.logger.debug "Shift requests params: #{shift_requests_params.inspect}"
    Rails.logger.debug "Memos params: #{memos_params.inspect}"
  
    ActiveRecord::Base.transaction do
      shift_requests_params.each do |employee_id, shifts|
        shifts.each do |date, shift_type|
          next if shift_type.blank?
  
          ShiftRequest.create!(
            employee_id: employee_id,
            date: Date.parse(date),
            shift_type: format_shift_type(shift_type),
            user: current_user
          )
        end
      end
  
      memos_params.each do |date, content|
        next if content.blank?
  
        Memo.create!(
          user: current_user,
          date: Date.parse(date),
          content: content
        )
      end
    end
  
    flash[:success] = '勤務希望を保存しました'
    redirect_to new_shift_path(year: params[:shift_request][:year], month: params[:shift_request][:month])
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to save: #{e.record.errors.full_messages}"
    flash[:danger] = '勤務希望の保存に失敗しました'
    render :new, status: :unprocessable_entity
  end

  def destroy
    @shift_request = ShiftRequest.find(params[:id])
    @shift_request.destroy
    redirect_to shift_requests_path
  end

  private

  def shift_request_params
    params.require(:shift_request).permit(:year, :month, shift_requests: {}, memos: {})
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
    Rails.logger.debug "Year: #{params[:year] || params.dig(:shift_request, :year)}, Month: #{params[:month] || params.dig(:shift_request, :month)}"
    @employees = Employee.all
    @shifts = Shift.all.group_by(&:employee_id)
    @shift_requests = ShiftRequest.where(date: @start_date..@end_date)
    @memos = current_user.memos.where(date: @start_date..@end_date).index_by(&:date)
    set_month_data(params[:year], params[:month])
  end
end
