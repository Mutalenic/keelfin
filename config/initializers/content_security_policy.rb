# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    # Scripts: self + Tailwind CDN + Chart.js (jsdelivr) + Cloudflare Analytics + unsafe-inline for Turbo compatibility
    policy.script_src  :self, :unsafe_inline,
                       'https://cdn.tailwindcss.com',
                       'https://cdn.jsdelivr.net',
                       'https://static.cloudflareinsights.com'

    # Styles: self + Font Awesome (cdnjs) + Google Fonts + inline (required by Tailwind CDN)
    policy.style_src   :self, :unsafe_inline,
                       'https://cdnjs.cloudflare.com',
                       'https://fonts.googleapis.com'

    # Fonts: self + Font Awesome + Google Fonts
    policy.font_src    :self, :data,
                       'https://cdnjs.cloudflare.com',
                       'https://fonts.googleapis.com',
                       'https://fonts.gstatic.com'

    # Images: self + data URIs (for inline chart images)
    policy.img_src     :self, :data, :blob

    # Disallow plugins (Flash, etc.)
    policy.object_src  :none

    # Allow XHR/fetch to self + jsdelivr (for Chart.js source maps)
    policy.connect_src :self, 'https://cdn.jsdelivr.net'

    # Restrict framing to same origin
    policy.frame_ancestors :self
  end

  # Note: Nonce directives disabled for Turbo compatibility
  # Turbo caches pages with nonce attributes, causing stale nonce errors on restore
  # unsafe_inline is acceptable here since all inline scripts are controlled by the application
end
