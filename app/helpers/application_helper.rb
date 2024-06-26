module ApplicationHelper
  def flash_design(type)
    case type.to_sym
    when :success then "bg-blue bg-opacity-20 text-gray rouded px-8 py-5"
    when :danger then "bg-beige text-gray rouded px-8 py-5"
    else "bg-gray"
    end
  end
end
