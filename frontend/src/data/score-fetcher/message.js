export const ScoreFetcherCommand = Object.freeze({
  StartFetching: 'start-fetching'
})

export class ScoreFetcherMessage {
  /**
   * @param command {string}
   */
  constructor(command) {
    this.command = command;
  }
}
