export const ScoreFetcherCommand = Object.freeze({
  StartUpdatingScores: 'start-updating-scores'
})
export const ScoresEvent = Object.freeze({
  ScoresFetched: 'scores-fetched'
});

export class ScoreFetcherMessage {
  /**
   * @param command {string}
   */
  constructor(command) {
    this.command = command;
  }
}
