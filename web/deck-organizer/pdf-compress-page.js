import {compressAttachment} from './pdf-compress-ui.js';

const input = document.getElementById('compressFile');
const button = document.getElementById('compressPdf');
const status = document.getElementById('compressStatus');

button.onclick = () => {
  status.textContent = '';
  input.value = '';
  input.click();
};

input.onchange = async () => {
  const file = input.files[0];
  if (!file) return;
  button.disabled = true;
  try {
    if (file.size > 20 * 1024 * 1024) throw new Error('File exceeds 20 MB. Use a smaller file.');
    const signature = await file.slice(0, 5).text();
    if (signature !== '%PDF-') throw new Error('Choose a PDF file.');
    await compressAttachment({blob: file, name: file.name}, button, status);
  } catch (error) {
    status.textContent = error.message || 'Could not open this PDF.';
  } finally {
    button.disabled = false;
  }
};
