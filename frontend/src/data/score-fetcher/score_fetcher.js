import {ScoreFetcherCommand, ScoreFetcherMessage, ScoresEvent} from "./message.js";

/**
 * @callback messageCallback
 * @param {ScoreFetcherMessage} message is the message received from the worker
 */
/**
 * @callback scoresUpdatedCallback
 */

export class ScoreFetcher {
  constructor() {
    this.worker = new Worker(new URL('worker.js', import.meta.url), {type: 'module'});

    /** @type {messageCallback[]} */
    this.messageListeners = [];

    this.worker.onmessage = (event) => {
      console.log('from worker:', event);
      /** @type {ScoreFetcherMessage} */
      const message = event.data;
      for (let listener of this.messageListeners) {
        listener(message);
      }
    };

    this.worker.onmessageerror = (message) => {
      console.error('worker message error:', message);
    };

    this.worker.onerror = (message) => {
      console.error('worker error:', message, message.error, message.message);
    };
  }

  updatingScores() {
    this.worker.postMessage(new ScoreFetcherMessage(ScoreFetcherCommand.StartUpdatingScores));
  }

  /**
   * @param {scoresUpdatedCallback} callback
   */
  listenForScoresUpdated(callback) {
    this.messageListeners.push(function (message) {
      if (message.command === ScoresEvent.ScoresFetched) {
        callback();
      }
    });
  }
}

export const scoreFetcher = new ScoreFetcher();
