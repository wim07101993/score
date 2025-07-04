import {Database} from "./data/database/database.js";
import {ScoresApi} from "./data/api/scores-api.js";

export class AppState {
  constructor() {
    this.database = new Database();
    this.api = new ScoresApi();
    this.initialization = this._initialize();
  }

  async _initialize() {
    await this.database.connect();
    return this;
  }
}

export const appState = new AppState();
