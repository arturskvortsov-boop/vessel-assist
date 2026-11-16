const ANALYTICS_SCREENS = new Set([
  '/',
  '/admin',
  '/admin/backup',
  '/admin/compress_pdf',
  '/admin/compress_photos',
  '/admin/date_time_stamper',
  '/admin/documents',
  '/admin/organizer',
  '/admin/scan_to_pdf',
  '/admin/unit_converter',
  '/deck',
  '/deck/ballast_sequence',
  '/deck/ballast_time',
  '/deck/cargo',
  '/deck/cargo_tanks',
  '/deck/compass_error',
  '/deck/compress_pdf',
  '/deck/draft_survey',
  '/deck/eta',
  '/deck/gm_roll',
  '/deck/logbook',
  '/deck/nav',
  '/deck/ops',
  '/deck/organizer',
  '/deck/port_distance',
  '/deck/port_time_zone',
  '/deck/ports',
  '/deck/safety_depth',
  '/deck/tasks',
  '/deck/true_wind',
  '/deck/ukc',
  '/engine',
  '/engine/admin_tab',
  '/engine/backup',
  '/engine/bunker_checklist',
  '/engine/changeover',
  '/engine/daily_ops',
  '/engine/delivery',
  '/engine/documents',
  '/engine/egcs',
  '/engine/emergency',
  '/engine/fuel_log',
  '/engine/hours',
  '/engine/lop',
  '/engine/lube',
  '/engine/marpol',
  '/engine/night_orders',
  '/engine/notes',
  '/engine/orb',
  '/engine/pump',
  '/engine/spares',
  '/engine/tanks',
  '/engine/tasks',
  '/engine/voyage',
  '/engine/warranty',
  '/help',
  '/splash',
]);

const ANALYTICS_COLUMNS = [
  'Batch ID', 'Event ID', 'Event time (UTC)', 'Event', 'Screen',
  'Platform', 'App version', 'Received time (UTC)',
];

function doPost(e) {
  let batch;
  try {
    const body = e.postData.contents;
    if (body.length > 250000) return analyticsReceipt(false, undefined, true);
    batch = JSON.parse(body);
  } catch (_) {
    return analyticsReceipt(false, undefined, true);
  }

  if (!batch || !isAnalyticsId(batch.id) || !Array.isArray(batch.events) ||
      batch.events.length < 1 || batch.events.length > 500 ||
      batch.events[0]?.id !== batch.id) {
    return analyticsReceipt(false, undefined, true);
  }

  const seen = new Set();
  const latest = Date.now() + 86400000;
  const events = batch.events.filter(event => {
    if (!isAnalyticsEvent(event) || Date.parse(event.created_at) > latest || seen.has(event.id)) {
      return false;
    }
    seen.add(event.id);
    return true;
  });
  if (!events.length) {
    return analyticsReceipt(false, batch.id, true);
  }

  const lock = LockService.getScriptLock();
  if (!lock.tryLock(5000)) return analyticsReceipt(false);
  try {
    const sheetId = PropertiesService.getScriptProperties().getProperty('ANALYTICS_SHEET_ID');
    if (!sheetId) return analyticsReceipt(false);

    const book = SpreadsheetApp.openById(sheetId);
    const sheet = book.getSheetByName('Events') || book.insertSheet('Events');
    if (sheet.getLastRow() === 0) {
      sheet.getRange(1, 1, 1, ANALYTICS_COLUMNS.length).setValues([ANALYTICS_COLUMNS]);
      sheet.setFrozenRows(1);
    }
    const lastRow = sheet.getLastRow();
    if (lastRow > 1 && sheet.getRange(2, 1, lastRow - 1, 1)
        .createTextFinder(batch.id).matchEntireCell(true).findNext()) {
      return analyticsReceipt(true, batch.id);
    }

    const received = new Date().toISOString();
    const rows = events.map(event => [
      batch.id, event.id, event.created_at, event.event, event.screen || '',
      event.platform, event.app_version, received,
    ]);
    const maxRows = sheet.getMaxRows();
    if (lastRow + rows.length > maxRows) {
      sheet.insertRowsAfter(maxRows, lastRow + rows.length - maxRows);
    }
    const range = sheet.getRange(lastRow + 1, 1, rows.length, ANALYTICS_COLUMNS.length);
    range.setNumberFormat('@');
    range.setValues(rows);
    SpreadsheetApp.flush();
    return analyticsReceipt(true, batch.id);
  } catch (error) {
    console.error('Could not store analytics batch');
    return analyticsReceipt(false);
  } finally {
    lock.releaseLock();
  }
}

function isAnalyticsId(value) {
  return typeof value === 'string' && /^[0-9a-f]{32}$/.test(value);
}

function isAnalyticsEvent(event) {
  if (!event || !isAnalyticsId(event.id) ||
      typeof event.created_at !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$/.test(event.created_at) ||
      !Number.isFinite(Date.parse(event.created_at)) ||
      typeof event.platform !== 'string' ||
      !/^(web|android|iOS|linux|macOS|windows|fuchsia)$/.test(event.platform) ||
      typeof event.app_version !== 'string' ||
      !/^[a-zA-Z0-9][a-zA-Z0-9.+_-]{0,63}$/.test(event.app_version)) {
    return false;
  }
  return (event.event === 'app_open' && event.screen === undefined) ||
      (event.event === 'screen_view' && typeof event.screen === 'string' &&
       ANALYTICS_SCREENS.has(event.screen));
}

function analyticsReceipt(accepted, id, rejected) {
  return ContentService.createTextOutput(JSON.stringify({ accepted, id, rejected }))
    .setMimeType(ContentService.MimeType.JSON);
}
