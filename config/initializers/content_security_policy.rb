# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    # Scripts: self + Tailwind CDN + Chart.js (jsdelivr)
    policy.script_src  :self,
                       'https://cdn.tailwindcss.com',
                       'https://cdn.jsdelivr.net'

    # Styles: self + Font Awesome (cdnjs) + inline (required by Tailwind CDN)
    policy.style_src   :self, :unsafe_inline,
                       'https://cdnjs.cloudflare.com'

    # Fonts: self + Font Awesome
    policy.font_src    :self, :data,
                       'https://cdnjs.cloudflare.com'

    # Images: self + data URIs (for inline chart images)
    policy.img_src     :self, :data, :blob

    # Disallow plugins (Flash, etc.)
    policy.object_src  :none

    # Allow XHR/fetch to self only
    policy.connect_src :self

    # Restrict framing to same origin
    policy.frame_ancestors :self
  end

  # Generate a cryptographically strong random nonce per-request (never reuse session ID)
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
