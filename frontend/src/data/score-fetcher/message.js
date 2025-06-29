export const ScoreFetcherCommand = Object.freeze({
  StartUpdatingScores: 'start-updating-scores'
})

export class ScoreFetcherMessage {
  /**
   * @param command {string}
   */
  constructor(command) {
    this.command = command;
  }
}
