export function envelope(config, subject) {
  return { from: config.mailer.from, to: config.mailer.recipients.join(", "), subject };
}
