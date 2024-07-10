class ApplicationController < ActionController::Base
  before_action :require_login
  add_flash_types :success, :danger

  def set_month_data(year = nil, month = nil)
    Rails.logger.debug "Calling set_month_data in ShiftsController#index"
    @year = year ? year.to_i : Date.current.year
    @month = month ? month.to_i : Date.current.month

    date_now = Date.new(@year, @month)
    @weeks = ["日", "月", "火", "水", "木", "金", "土"]

    month_names = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    @month_name = month_names[date_now.month - 1]

    @start_date = date_now.beginning_of_month
    @end_date = date_now.end_of_month
    @calendar = (@start_date..@end_date).to_a
    @shift_calendar = "#{@start_date.year}年#{@start_date.month}月1日〜#{@end_date.month}月#{@end_date.day}日"
  end

  private
  
  def not_authenticated
    redirect_to login_path
  end
end
