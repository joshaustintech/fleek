class Mailer
  def deliver(user, subject:)
    message = build(user.email, subject, user.locale || :en)
    message.attach(user.avatar) if user.avatar && user.avatar.attached?
    message.send!
  end
end
