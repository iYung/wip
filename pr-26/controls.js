(function () {
  // Ensure viewport meta tag exists for correct mobile scaling
  if (!document.querySelector('meta[name="viewport"]')) {
    var meta = document.createElement('meta');
    meta.name = 'viewport';
    meta.content = 'width=device-width, initial-scale=1.0';
    document.head.appendChild(meta);
  }

  var style = document.createElement('style');
  style.textContent = [
    // Scale the canvas to fit the viewport width while keeping aspect ratio.
    // Canvas has intrinsic dimensions (1280x720) so height:auto preserves 16:9.
    'html, body {',
    '  margin: 0;',
    '  padding: 0;',
    '  background: #000;',
    '  overflow-x: hidden;',
    '}',
    '#canvas {',
    '  display: block;',
    '  width: 100% !important;',
    '  height: auto !important;',
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

  document.addEventListener('DOMContentLoaded', function () {
    var canvas = document.getElementById('canvas');

    function fireKey(type, key, code) {
      if (!canvas) { canvas = document.getElementById('canvas'); }
      if (!canvas) { return; }
      canvas.dispatchEvent(new KeyboardEvent(type, { key: key, code: code, bubbles: true }));
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
  });
}());
