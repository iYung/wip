(function () {
  // Task A — Fake gamepad scaffold (injected before DOMContentLoaded so
  // Emscripten reads it on startup via navigator.getGamepads).
  window.__fakeGamepad = {
    id: 'Fake Gamepad',
    index: 0,
    mapping: 'standard',
    connected: false,
    timestamp: 0,
    axes: [0, 0, 0, 0],
    buttons: (function () {
      var btns = [];
      for (var i = 0; i < 16; i++) { btns.push({ pressed: false, value: 0 }); }
      return btns;
    }())
  };
  navigator.getGamepads = function () {
    return window.__fakeGamepad.connected ? [window.__fakeGamepad] : [];
  };

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
    '#game-controls .cluster-gamepad-left {',
    '  display: grid;',
    '  grid-template-columns: repeat(3, 60px);',
    '  grid-template-rows: repeat(2, 60px);',
    '  gap: 6px;',
    '}',
    '#game-controls .cluster-gamepad-right {',
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
    '#game-controls .btn-toggle {',
    '  min-width: 40px;',
    '  min-height: 40px;',
    '  background: rgba(255,255,255,0.1);',
    '  color: white;',
    '  border: 1px solid rgba(255,255,255,0.3);',
    '  border-radius: 8px;',
    '  font-size: 16px;',
    '  cursor: pointer;',
    '  user-select: none;',
    '  -webkit-user-select: none;',
    '  touch-action: none;',
    '  align-self: center;',
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
    '#game-controls .btn-space {',
    '  grid-column: 1 / span 2;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-esc {',
    '  grid-column: 1 / span 2;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-gp-up {',
    '  grid-column: 2;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-gp-left {',
    '  grid-column: 1;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-gp-down {',
    '  grid-column: 2;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-gp-right {',
    '  grid-column: 3;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-gp-a {',
    '  grid-column: 1;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-gp-b {',
    '  grid-column: 2;',
    '  grid-row: 1;',
    '}',
    '#game-controls .btn-gp-y {',
    '  grid-column: 1;',
    '  grid-row: 2;',
    '}',
    '#game-controls .btn-gp-start {',
    '  grid-column: 2;',
    '  grid-row: 2;',
    '}'
  ].join('\n');
  document.head.appendChild(style);

  // love.js's WASM SDL layer reads e.keyCode (a legacy numeric code) to
  // determine which key was pressed. Synthetic events default to keyCode=0
  // which SDL maps to nothing, so all button presses are silently ignored.
  var KEY_CODES = {
    'w': 87, 'a': 65, 's': 83, 'd': 68,
    ' ': 32, 'Escape': 27
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

    // Task B — Fake gamepad button helper
    function attachGamepadButton(btn, index) {
      btn.addEventListener('mousedown', function () {
        window.__fakeGamepad.buttons[index].pressed = true;
        window.__fakeGamepad.buttons[index].value = 1;
        window.__fakeGamepad.timestamp = performance.now();
      });
      btn.addEventListener('mouseup', function () {
        window.__fakeGamepad.buttons[index].pressed = false;
        window.__fakeGamepad.buttons[index].value = 0;
      });
      btn.addEventListener('mouseleave', function () {
        window.__fakeGamepad.buttons[index].pressed = false;
        window.__fakeGamepad.buttons[index].value = 0;
      });
      btn.addEventListener('touchstart', function (e) {
        e.preventDefault();
        window.__fakeGamepad.buttons[index].pressed = true;
        window.__fakeGamepad.buttons[index].value = 1;
        window.__fakeGamepad.timestamp = performance.now();
      }, { passive: false });
      btn.addEventListener('touchend', function (e) {
        e.preventDefault();
        window.__fakeGamepad.buttons[index].pressed = false;
        window.__fakeGamepad.buttons[index].value = 0;
      }, { passive: false });
      btn.addEventListener('touchcancel', function (e) {
        e.preventDefault();
        window.__fakeGamepad.buttons[index].pressed = false;
        window.__fakeGamepad.buttons[index].value = 0;
      }, { passive: false });
    }

    var controls = document.createElement('div');
    controls.id = 'game-controls';

    // Left cluster: d-pad (keyboard)
    var leftCluster = document.createElement('div');
    leftCluster.className = 'cluster-left';

    var btnUp = document.createElement('button');
    btnUp.className = 'btn-up';
    btnUp.textContent = 'W';
    attachButton(btnUp, 'w', 'KeyW');

    var btnLeft = document.createElement('button');
    btnLeft.className = 'btn-left';
    btnLeft.textContent = 'A';
    attachButton(btnLeft, 'a', 'KeyA');

    var btnDown = document.createElement('button');
    btnDown.className = 'btn-down';
    btnDown.textContent = 'S';
    attachButton(btnDown, 's', 'KeyS');

    var btnRight = document.createElement('button');
    btnRight.className = 'btn-right';
    btnRight.textContent = 'D';
    attachButton(btnRight, 'd', 'KeyD');

    leftCluster.appendChild(btnUp);
    leftCluster.appendChild(btnLeft);
    leftCluster.appendChild(btnDown);
    leftCluster.appendChild(btnRight);

    // Right cluster: action buttons (keyboard)
    var rightCluster = document.createElement('div');
    rightCluster.className = 'cluster-right';

    var btnSpace = document.createElement('button');
    btnSpace.className = 'btn-space';
    btnSpace.textContent = 'Space';
    attachButton(btnSpace, ' ', 'Space');

    var btnEsc = document.createElement('button');
    btnEsc.className = 'btn-esc';
    btnEsc.textContent = 'Esc';
    attachButton(btnEsc, 'Escape', 'Escape');

    rightCluster.appendChild(btnSpace);
    rightCluster.appendChild(btnEsc);

    // Task C — Gamepad left cluster: D-pad (indices 12↑ 13↓ 14← 15→)
    var gpLeftCluster = document.createElement('div');
    gpLeftCluster.className = 'cluster-gamepad-left';
    gpLeftCluster.style.display = 'none';

    var gpBtnUp = document.createElement('button');
    gpBtnUp.className = 'btn-gp-up';
    gpBtnUp.textContent = '↑';
    attachGamepadButton(gpBtnUp, 12);

    var gpBtnLeft = document.createElement('button');
    gpBtnLeft.className = 'btn-gp-left';
    gpBtnLeft.textContent = '←';
    attachGamepadButton(gpBtnLeft, 14);

    var gpBtnDown = document.createElement('button');
    gpBtnDown.className = 'btn-gp-down';
    gpBtnDown.textContent = '↓';
    attachGamepadButton(gpBtnDown, 13);

    var gpBtnRight = document.createElement('button');
    gpBtnRight.className = 'btn-gp-right';
    gpBtnRight.textContent = '→';
    attachGamepadButton(gpBtnRight, 15);

    gpLeftCluster.appendChild(gpBtnUp);
    gpLeftCluster.appendChild(gpBtnLeft);
    gpLeftCluster.appendChild(gpBtnDown);
    gpLeftCluster.appendChild(gpBtnRight);

    // Task C — Gamepad right cluster: A (0), B (1), Y (3), Start (9)
    var gpRightCluster = document.createElement('div');
    gpRightCluster.className = 'cluster-gamepad-right';
    gpRightCluster.style.display = 'none';

    var gpBtnA = document.createElement('button');
    gpBtnA.className = 'btn-gp-a';
    gpBtnA.textContent = 'A';
    attachGamepadButton(gpBtnA, 0);

    var gpBtnB = document.createElement('button');
    gpBtnB.className = 'btn-gp-b';
    gpBtnB.textContent = 'B';
    attachGamepadButton(gpBtnB, 1);

    var gpBtnY = document.createElement('button');
    gpBtnY.className = 'btn-gp-y';
    gpBtnY.textContent = 'Y';
    attachGamepadButton(gpBtnY, 3);

    var gpBtnStart = document.createElement('button');
    gpBtnStart.className = 'btn-gp-start';
    gpBtnStart.textContent = 'Start';
    attachGamepadButton(gpBtnStart, 9);

    gpRightCluster.appendChild(gpBtnA);
    gpRightCluster.appendChild(gpBtnB);
    gpRightCluster.appendChild(gpBtnY);
    gpRightCluster.appendChild(gpBtnStart);

    // Task D — Mode toggle button
    var currentMode = 'keyboard';
    var toggleBtn = document.createElement('button');
    toggleBtn.className = 'btn-toggle';
    toggleBtn.textContent = '⌨';
    toggleBtn.addEventListener('click', function () {
      if (currentMode === 'keyboard') {
        // Switch to gamepad mode
        window.__fakeGamepad.connected = true;
        window.__fakeGamepad.timestamp = performance.now();
        var connectEv = new Event('gamepadconnected'); connectEv.gamepad = window.__fakeGamepad; window.dispatchEvent(connectEv);
        leftCluster.style.display = 'none';
        rightCluster.style.display = 'none';
        gpLeftCluster.style.display = '';
        gpRightCluster.style.display = '';
        toggleBtn.textContent = '🎮';
        currentMode = 'gamepad';
      } else {
        // Switch to keyboard mode
        window.__fakeGamepad.connected = false;
        var disconnectEv = new Event('gamepaddisconnected'); disconnectEv.gamepad = window.__fakeGamepad; window.dispatchEvent(disconnectEv);
        gpLeftCluster.style.display = 'none';
        gpRightCluster.style.display = 'none';
        leftCluster.style.display = '';
        rightCluster.style.display = '';
        toggleBtn.textContent = '⌨';
        currentMode = 'keyboard';
      }
    });

    controls.appendChild(leftCluster);
    controls.appendChild(toggleBtn);
    controls.appendChild(rightCluster);
    controls.appendChild(gpLeftCluster);
    controls.appendChild(gpRightCluster);
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
