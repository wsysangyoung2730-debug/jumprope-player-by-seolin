/* 기존 HTML을 사용하던 브라우저의 해당 페이지에서 실행합니다.
   jrp: 이름 공간만 읽습니다. 네트워크 전송 없이 JSON을 다운로드합니다. */
(() => {
  const entries = {};
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (!key.startsWith('jrp:')) continue;
    const raw = localStorage.getItem(key);
    try { entries[key] = JSON.parse(raw); } catch { entries[key] = raw; }
  }
  const blob = new Blob([JSON.stringify({format:'seolin-jumprope-browser',version:1,entries},null,2)], {type:'application/json'});
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url; link.download = 'SEOLIN-JUMPROPE-browser-backup.json'; link.click();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
  return `${Object.keys(entries).length}개 저장 항목을 내보냈습니다.`;
})();
