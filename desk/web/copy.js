// %shelf — the page's only script. Reveals Copy buttons (rendered `hidden`
// so they never appear without JS) and copies their data-copy text.
document.querySelectorAll('button[data-copy]').forEach((btn) => {
  if (!navigator.clipboard) return; // needs a secure context (https)
  btn.hidden = false;
  const label = btn.textContent;
  btn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(btn.dataset.copy);
    } catch (e) {
      return;
    }
    btn.textContent = 'Copied';
    clearTimeout(btn._t);
    btn._t = setTimeout(() => { btn.textContent = label; }, 1400);
  });
});
