module ApplicationHelper
  def dummy_page_nav(title:, subtitle: nil, back_url: nil, back_label: "Home")
    content_for(:title, title)
    content_for(:subtitle, subtitle) if subtitle.present?

    page_nav = { round: true, style: :default }
    if back_url.present?
      page_nav[:back_href] = back_url
      page_nav[:back_tooltip] = back_label
    end
    flat_pack_page_nav(**page_nav)

    recording_studio_page_nav_right do
      concat recording_studio_root_switch_dropdown(style: :ghost, size: :md)
    end

    register_page_nav(
      "Sign out",
      main_app.destroy_user_session_path,
      role: :secondary,
      data: { turbo_method: :delete }
    )
  end
end
