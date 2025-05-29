import {ScoreFetcherCommand, ScoreFetcherMessage} from "./message.js";

/**
 * @type {Worker|null}
 */
let worker = null;

export function startScoreFetchingBackgroundWorker() {
  if (worker != null) {
    worker.terminate();
  }
  worker = new Worker('score_fetcher/worker.js', {type: 'module'});

  worker.onmessage = (message) => {
    console.log('from worker:', message);
  };

  worker.onmessageerror = (message) => {
    console.log('worker message error:', message);
  };

  worker.onerror = (message) => {
    console.log('worker error:', message, message.error, message.message);
  };

  worker.postMessage(new ScoreFetcherMessage(ScoreFetcherCommand.StartFetching));
}
