import {ScoreFetcherCommand, ScoreFetcherMessage} from "./message.js";

/**
 * @type {Worker|null}
 */
let worker = null;

export function startScoreFetchingBackgroundWorker() {
  if (worker != null) {
    worker.terminate();
  }
  worker = new Worker(new URL('worker.js', import.meta.url), {type: 'module'});

  worker.onmessage = (message) => {
    console.log('from worker:', message);
  };

  worker.onmessageerror = (message) => {
    console.error('worker message error:', message);
  };

  worker.onerror = (message) => {
    console.error('worker error:', message, message.error, message.message);
  };

  worker.postMessage(new ScoreFetcherMessage(ScoreFetcherCommand.StartUpdatingScores));
}
