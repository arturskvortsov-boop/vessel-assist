// Add this as a separate .gs file in the analytics Apps Script project.
function setupOverview() {
  const book = overviewBook();
  const events = book.getSheetByName('Events');
  if (!events) throw new Error('Events sheet is missing.');
  let sheet = book.getSheetByName('Overview');
  if (sheet && sheet.getRange('A1').getValue() !== 'VESSEL ASSIST | USAGE') {
    throw new Error('An unrelated Overview sheet already exists.');
  }
  sheet = sheet || book.insertSheet('Overview', 0);
  book.setActiveSheet(sheet);
  book.moveActiveSheet(1);
  sheet.setHiddenGridlines(true);
  sheet.setFrozenRows(11);
  [285, 140, 170, 170, 140].forEach((width, i) => sheet.setColumnWidth(i + 1, width));
  sheet.getRange('A1:E1').merge().setValue('VESSEL ASSIST | USAGE')
    .setBackground('#122439').setFontColor('#ffffff').setFontSize(19).setFontWeight('bold');
  sheet.setRowHeight(1, 42);
  sheet.getRange('A3:A6').setValues([['Period (days)'], ['Section'], ['Platform'], ['App version']]);
  sheet.getRange('B3:B6').setValues([[7], ['All'], ['All'], ['All']]).setBackground('#e0f7fa');
  const choices = [['7','30'], ['All','Deck','Engine','Admin','Other'],
    ['All','web','android','iOS','windows','macOS','linux','fuchsia']];
  choices.forEach((values, i) => sheet.getRange(i + 3, 2).setDataValidation(
    SpreadsheetApp.newDataValidation().requireValueInList(values).setAllowInvalid(false).build(),
  ));
  sheet.getRange('B6').setNote('Enter an exact app version, or All.');
  sheet.getRange('A10:E10').merge().setValue('Screen openings are counted per visit. Test events are excluded.');
  sheet.getRange('A11:E11').setValues([['Tool', 'Section', 'Openings', 'Previous period', 'Change']])
    .setBackground('#183951').setFontColor('#ffffff').setFontWeight('bold');
  events.hideColumns(1, 2);
  refreshOverview();
  const triggers = ScriptApp.getProjectTriggers();
  if (!triggers.some(trigger => trigger.getHandlerFunction() === 'refreshOverview')) {
    ScriptApp.newTrigger('refreshOverview').timeBased().everyHours(1).create();
  }
  if (!triggers.some(trigger => trigger.getHandlerFunction() === 'overviewFilterChanged')) {
    ScriptApp.newTrigger('overviewFilterChanged').forSpreadsheet(book).onEdit().create();
  }
}

function overviewBook() {
  const id = PropertiesService.getScriptProperties().getProperty('ANALYTICS_SHEET_ID');
  if (!id) throw new Error('Set ANALYTICS_SHEET_ID in Script properties.');
  return SpreadsheetApp.openById(id);
}

function overviewFilterChanged(e) {
  const range = e.range;
  if (range.getSheet().getName() === 'Overview' &&
      range.getColumn() <= 2 && range.getLastColumn() >= 2 &&
      range.getRow() <= 6 && range.getLastRow() >= 3) {
    refreshOverview();
  }
}

function refreshOverview() {
  const book = overviewBook();
  const sheet = book.getSheetByName('Overview');
  const events = book.getSheetByName('Events');
  if (!sheet || !events) return;
  const [days, section, platform, version] = sheet.getRange('B3:B6').getValues().flat();
  const rows = events.getLastRow() > 1
    ? events.getRange(2, 3, events.getLastRow() - 1, 5).getValues() : [];
  const now = new Date();
  const result = summarizeOverview(rows, now, Number(days) === 30 ? 30 : 7, section, platform, version);
  sheet.getRange('A8:E9').setValues([
    ['App launches', 'Deck openings', 'Engine openings', 'Admin openings', 'Updated (UTC)'],
    [...result.totals, now.toISOString().slice(0, 16).replace('T', ' ')],
  ]);
  sheet.getRange('A8:E8').setFontWeight('bold').setBackground('#dcecf6');
  const existing = Math.max(1, sheet.getLastRow() - 11);
  sheet.getRange(12, 1, existing, 5).clearContent();
  const ranking = result.ranking.length ? result.ranking : [['No matching tool visits', '', '', '', '']];
  sheet.getRange(12, 1, ranking.length, 5).setValues(ranking);
}

function summarizeOverview(rows, now, days, section, platform, version) {
  const end = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1);
  const span = days * 86400000;
  const start = end - span;
  const totals = [0, 0, 0, 0];
  const tools = new Map();
  for (const [date, event, path, device, release] of rows) {
    const time = new Date(date).getTime();
    if (!Number.isFinite(time) || time < start - span || time >= end ||
        /^test/i.test(String(release)) || path === '/integration_test' ||
        (platform !== 'All' && device !== platform) ||
        (version && version !== 'All' && String(release) !== String(version))) continue;
    const current = time >= start;
    if (event === 'app_open') {
      if (current) totals[0]++;
      continue;
    }
    if (event !== 'screen_view' || typeof path !== 'string' ||
        !/^\/[a-z0-9_/]*$/.test(path)) continue;
    const prefix = path.split('/')[1];
    const groups = { deck: 'Deck', engine: 'Engine', admin: 'Admin' };
    const group = groups[prefix] || 'Other';
    if (current && groups[prefix]) totals[['Deck','Engine','Admin'].indexOf(group) + 1]++;
    if (section !== 'All' && section !== group) continue;
    const title = OVERVIEW_TOOL_NAMES[path];
    if (!title && path.split('/').length < 3) continue;
    // Navigation tabs and top-level sections contribute to section totals only.
    if (OVERVIEW_NAVIGATION.has(path)) continue;
    const item = tools.get(path) || [title || path, group, 0, 0, 0];
    item[current ? 2 : 3]++;
    item[4] = item[2] - item[3];
    tools.set(path, item);
  }
  return { totals, ranking: [...tools.values()].sort((a, b) =>
    b[2] - a[2] || b[3] - a[3] || a[0].localeCompare(b[0])) };
}

const OVERVIEW_NAVIGATION = new Set([
  '/', '/deck', '/engine', '/admin', '/deck/nav', '/deck/cargo', '/deck/ops',
  '/engine/marpol', '/engine/daily_ops', '/engine/admin_tab',
]);

const OVERVIEW_TOOL_NAMES = {
  "/deck/eta": "ETA Calculator",
  "/deck/port_time_zone": "Port Time Zone",
  "/deck/port_distance": "Port Distance",
  "/deck/true_wind": "True Wind Calculator",
  "/deck/compass_error": "Compass Error Calculator",
  "/deck/ukc": "UKC Calculator",
  "/deck/safety_depth": "Safety Depth",
  "/deck/cargo_tanks": "Cargo Tanks",
  "/deck/draft_survey": "Draft Survey",
  "/deck/ballast_time": "Ballast Time",
  "/deck/gm_roll": "GM Estimate",
  "/deck/logbook": "Logbook Records",
  "/deck/tasks": "Crew Tasks",
  "/deck/ports": "Port Codes",
  "/engine/tanks": "Tank Status",
  "/engine/orb": "ORB Generator",
  "/engine/changeover": "Fuel Changeover",
  "/engine/egcs": "EGCS Record Book",
  "/engine/bunker_checklist": "Bunkering Checklists",
  "/engine/lop": "Letters of Protest",
  "/engine/fuel_log": "Fuel Daily Log",
  "/engine/lube": "Lube Oil",
  "/engine/pump": "Pump Calculator",
  "/engine/voyage": "Voyage Plan",
  "/engine/hours": "Engine Hours",
  "/engine/night_orders": "Night Orders",
  "/engine/tasks": "Crew Tasks",
  "/engine/emergency": "Emergency",
  "/engine/spares": "Spares & Stores",
  "/engine/warranty": "Warranty Claims",
  "/engine/delivery": "Delivery & Acceptance",
  "/engine/notes": "Notes",
  "/engine/documents": "Document Storage",
  "/engine/backup": "Backup & Restore",
  "/admin/documents": "Document Storage",
  "/admin/organizer": "Organizer",
  "/admin/scan_to_pdf": "Scan to PDF",
  "/admin/date_time_stamper": "Date & Time Stamper",
  "/admin/unit_converter": "Unit Converter",
  "/admin/compress_photos": "Compress Photos",
  "/admin/compress_pdf": "Compress PDF",
  "/admin/backup": "Backup & Restore",
  "/help": "Help & Feedback",
  "/deck/ballast_sequence": "Ballast Sequence"
};
