(function () {
  // Ensure viewport meta tag exists for correct mobile scaling
  if (!document.querySelector('meta[name="viewport"]')) {
    var meta = document.createElement('meta');
    meta.name = 'viewport';
    meta.content = 'width=device-width, initial-scale=1.0';
    document.head.appendChild(meta);
  }

  // love.js sets canvas dimensions via JS inline styles after page load.
  // CSS !important alone loses that race, so we force-apply via setProperty
  // every 100 ms for the first 3 seconds, then on every resize.
  function scaleCanvas() {
    var c = document.getElementById('canvas');
    if (!c) return;
    var vw = window.innerWidth;
    var vh = Math.round(vw * 720 / 1280);
    c.style.setProperty('width',  vw + 'px', 'important');
    c.style.setProperty('height', vh + 'px', 'important');
  }
  scaleCanvas();
  window.addEventListener('resize', scaleCanvas);
  var _poll = setInterval(scaleCanvas, 100);
  setTimeout(function () { clearInterval(_poll); }, 3000);

  var style = document.createElement('style');
  style.textContent = [
    'html, body {',
    '  margin: 0;',
    '  padding: 0;',
    '  background: #000;',
    '  overflow-x: hidden;',
    '}',
    '#game-controls {',
    '  display: flex;',
    '  flex-direction: row;',
    '  justify-content: space-between;',
    '  padding: 12px;',
    '  background: rgba(0,0,0,0.7);',
    '  width: 100%;',
    '  margin: 0;',
    '  box-sizing: border-box;',
    '}',
    '#game-controls .cluster-left {',
    '  display: grid;',
    '  grid-template-columns: repeat(3, 60px);',
    '  grid-template-rows: repeat(2, 60px);',
    '  gap: 6px;',
    '}',
    '#game-controls .cluster-right {',
    '  display: grid;',
    '  grid-template-columns: repeat(2, 60px);',
    '  grid-template-rows: repeat(2, 60px);',
    '  gap: 6px;',
    '}',
    '#game-controls button {',
    '  min-width: 60px;',
    '  min-height: 60px;',
    '  background: rgba(255,255,255,0.15);',
    '  color: white;',
    '  border: 1px solid rgba(255,255,255,0.3);',
    '  border-radius: 8px;',
    '  font-size: 18px;',
    '  cursor: pointer;',
    '  user-select: none;',
    '  -webkit-user-select: none;',
    '  touch-action: none;',
    '}',
    '#game-controls button:active {',
    '  background: rgba(255,255,255,0.35);',
    '}',
    '#save-controls {',
    '  display: flex;',
    '  justify-content: center;',
    '  padding: 8px 12px;',
    '  background: rgba(0,0,0,0.5);',
    '  width: 100%;',
    '  box-sizing: border-box;',
    '}',
    '#save-controls .btn-clear-save {',
    '  min-width: unset;',
    '  min-height: unset;',
    '  padding: 6px 16px;',
    '  font-size: 13px;',
    '  background: rgba(180,40,40,0.5);',
    '  border-color: rgba(255,80,80,0.5);',
    '}',
    '#save-controls .btn-clear-save:active {',
    '  background: rgba(220,60,60,0.75);',
    '}',
    '#game-controls .btn-up {',
    '  grid-column: 2;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-left {',
    '  grid-column: 1;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-down {',
    '  grid-column: 2;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-right {',
    '  grid-column: 3;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-e {',
    '  grid-column: 1;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-f {',
    '  grid-column: 2;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-esc {',
    '  grid-column: 1 / span 2;',
    '  grid-row: 2;',
    '}'
  ].join('\n');
  document.head.appendChild(style);

  // love.js's WASM SDL layer reads e.keyCode (a legacy numeric code) to
  // determine which key was pressed. Synthetic events default to keyCode=0
  // which SDL maps to nothing, so all button presses are silently ignored.
  var KEY_CODES = {
    'ArrowLeft': 37, 'ArrowRight': 39, 'ArrowUp': 38, 'ArrowDown': 40,
    'e': 69, 'f': 70, 'Escape': 27
  };

  document.addEventListener('DOMContentLoaded', function () {
    var canvas = document.getElementById('canvas');

    function fireKey(type, key, code) {
      if (!canvas) { canvas = document.getElementById('canvas'); }
      if (!canvas) { return; }
      var kc = KEY_CODES[key] || 0;
      canvas.dispatchEvent(new KeyboardEvent(type, {
        key: key, code: code,
        keyCode: kc, which: kc, charCode: kc,
        bubbles: true, cancelable: true
      }));
    }

    function attachButton(btn, key, code) {
      btn.addEventListener('mousedown', function () {
        fireKey('keydown', key, code);
      });
      btn.addEventListener('mouseup', function () {
        fireKey('keyup', key, code);
      });
      btn.addEventListener('mouseleave', function () {
        fireKey('keyup', key, code);
      });
      btn.addEventListener('touchstart', function (e) {
        e.preventDefault();
        fireKey('keydown', key, code);
      }, { passive: false });
      btn.addEventListener('touchend', function (e) {
        e.preventDefault();
        fireKey('keyup', key, code);
      }, { passive: false });
      btn.addEventListener('touchcancel', function (e) {
        e.preventDefault();
        fireKey('keyup', key, code);
      }, { passive: false });
    }

    var controls = document.createElement('div');
    controls.id = 'game-controls';

    // Left cluster: d-pad
    var leftCluster = document.createElement('div');
    leftCluster.className = 'cluster-left';

    var btnUp = document.createElement('button');
    btnUp.className = 'btn-up';
    btnUp.textContent = '↑';
    attachButton(btnUp, 'ArrowUp', 'ArrowUp');

    var btnLeft = document.createElement('button');
    btnLeft.className = 'btn-left';
    btnLeft.textContent = '←';
    attachButton(btnLeft, 'ArrowLeft', 'ArrowLeft');

    var btnDown = document.createElement('button');
    btnDown.className = 'btn-down';
    btnDown.textContent = '↓';
    attachButton(btnDown, 'ArrowDown', 'ArrowDown');

    var btnRight = document.createElement('button');
    btnRight.className = 'btn-right';
    btnRight.textContent = '→';
    attachButton(btnRight, 'ArrowRight', 'ArrowRight');

    leftCluster.appendChild(btnUp);
    leftCluster.appendChild(btnLeft);
    leftCluster.appendChild(btnDown);
    leftCluster.appendChild(btnRight);

    // Right cluster: action buttons
    var rightCluster = document.createElement('div');
    rightCluster.className = 'cluster-right';

    var btnE = document.createElement('button');
    btnE.className = 'btn-e';
    btnE.textContent = 'E';
    attachButton(btnE, 'e', 'KeyE');

    var btnF = document.createElement('button');
    btnF.className = 'btn-f';
    btnF.textContent = 'F';
    attachButton(btnF, 'f', 'KeyF');

    var btnEsc = document.createElement('button');
    btnEsc.className = 'btn-esc';
    btnEsc.textContent = 'Esc';
    attachButton(btnEsc, 'Escape', 'Escape');

    rightCluster.appendChild(btnE);
    rightCluster.appendChild(btnF);
    rightCluster.appendChild(btnEsc);

    controls.appendChild(leftCluster);
    controls.appendChild(rightCluster);
    document.body.appendChild(controls);

    // Save controls bar below the main controls
    var saveControls = document.createElement('div');
    saveControls.id = 'save-controls';

    var btnClearSave = document.createElement('button');
    btnClearSave.className = 'btn-clear-save';
    btnClearSave.textContent = 'Clear All Data';
    btnClearSave.addEventListener('click', function () {
      if (!confirm('Delete your save and settings? This cannot be undone.')) return;
      var savePath = '/home/web_user/love/game/save.dat';
      var settingsPath = '/home/web_user/love/game/settings.dat';
      try {
        if (typeof Module !== 'undefined' && Module['FS_unlink']) {
          Module['FS_unlink'](savePath);
          try {
            Module['FS_unlink'](settingsPath);
          } catch (e) {
            // settings.dat not found — silently ignore
          }
          if (Module['FS_syncfs']) {
            Module['FS_syncfs'](false, function (err) {
              if (err) console.warn('[clear-save] sync error:', err);
              location.reload();
            });
          } else {
            location.reload();
          }
        } else {
          alert('Game not loaded yet — nothing to clear.');
        }
      } catch (e) {
        // save.dat not found is fine — just reload so the game sees no save
        try { Module['FS_unlink'](settingsPath); } catch (e2) { /* ignore */ }
        if (Module['FS_syncfs']) {
          Module['FS_syncfs'](false, function () { location.reload(); });
        } else {
          location.reload();
        }
      }
    });
    saveControls.appendChild(btnClearSave);
    document.body.appendChild(saveControls);
  });
}());
