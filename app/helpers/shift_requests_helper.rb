module ShiftRequestsHelper
  def format_display_shift_type(shift_type)
    case shift_type
    when '早番' then 'H'
    when '日勤' then 'N'
    when '遅番' then 'O'
    when '夜勤' then 'Y'
    when '休み' then '⚫️'
    else shift_type
    end
  end
end