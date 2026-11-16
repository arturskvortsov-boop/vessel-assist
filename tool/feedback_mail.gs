function doPost(e) {
  let request;
  try {
    const body = e.postData.contents;
    if (body.length > 40000) return receipt(false, undefined, true);
    request = JSON.parse(body);
  } catch (_) {
    return receipt(false, undefined, true);
  }

  const labels = { feedback: 'Feedback', bug: 'Bug Report', contact: 'Contact' };
  if (!request || !/^[a-f0-9]{32}$/.test(request.id) ||
      !Object.hasOwn(labels, request.type) ||
      typeof request.message !== 'string' ||
      !request.message.trim() || request.message.length > 6000) {
    return receipt(false, undefined, true);
  }

  const lock = LockService.getScriptLock();
  if (!lock.tryLock(5000)) return receipt(false);
  try {
    const settings = PropertiesService.getScriptProperties();
    const recipient = settings.getProperty('SUPPORT_RECIPIENT');
    if (!recipient) return receipt(false);
    const key = 'sent:' + request.id;
    if (settings.getProperty(key)) return receipt(true, request.id);

    const now = Date.now();
    const records = settings.getProperties();
    const cutoff = now - 30 * 86400000;
    let today = 0;
    for (const [name, timestamp] of Object.entries(records)) {
      if (!name.startsWith('sent:')) continue;
      if (Number(timestamp) < cutoff) settings.deleteProperty(name);
      if (Number(timestamp) > now - 86400000) today++;
    }
    if (today >= 25 || MailApp.getRemainingDailyQuota() < 1) return receipt(false);

    const email = typeof request.reply_to === 'string' ? request.reply_to : '';
    const mail = {
      to: recipient,
      subject: 'Vessel Assist · ' + labels[request.type],
      body: [
        'Received: ' + new Date(now).toISOString(),
        'Submitted: ' + field(request.created_at),
        'App version: ' + field(request.app_version),
        'Platform: ' + field(request.platform),
        'Section: ' + field(request.section),
        '',
        request.message.trim(),
      ].join('\n'),
    };
    if (email.length <= 254 && /^[^\s@,;]+@[^\s@,;]+\.[^\s@,;]+$/.test(email)) {
      mail.replyTo = email;
    }
    MailApp.sendEmail(mail);
    settings.setProperty(key, String(now));
    return receipt(true, request.id);
  } catch (_) {
    return receipt(false);
  } finally {
    lock.releaseLock();
  }
}

function field(value) {
  return typeof value === 'string' ? value.replace(/[\r\n]/g, ' ').slice(0, 120) : '';
}

function receipt(accepted, id, rejected) {
  return ContentService.createTextOutput(JSON.stringify({ accepted, id, rejected }))
    .setMimeType(ContentService.MimeType.JSON);
}
