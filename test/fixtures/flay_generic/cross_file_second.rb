# comment line

module Notifier
  def push(device, title:)
    payload = build(device.token, title, device.locale || :en)
    payload.attach(device.icon) if device.icon && device.icon.attached?
    payload.send!
  end
end
