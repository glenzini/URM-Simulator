'use strict';

// Load the engine into this worker scope — gives us a global URM with _internalApi.
importScripts('./urm-engine.js');

self.onmessage = function(e) {
  const { id, path, body } = e.data;
  try {
    self.postMessage({ id, result: URM._internalApi(path, body) });
  } catch(err) {
    self.postMessage({ id, result: { ok: false, error: err.message } });
  }
};
