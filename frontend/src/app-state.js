import {Database} from "./data/database/database.js";
import {ScoresApi} from "./data/api/scores-api.js";
import {authorize} from "./data/auth/auth.js";

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

    async fetchScoreUpdates() {
        await this.initialization;
        let newestScore = null;
        if (this.database.scores.length > 0) {
             newestScore = this.database.scores.reduce(
                (newest, score) => score.last_changed_at > newest.last_changed_at ? score : newest
            );
        }
        const lastFetchDate = newestScore?.last_changed_at ?? new Date(2000);

        const accessToken = await authorize();
        if (accessToken == null) {
            return;
        }
        const newScores = await this.api.getScores(lastFetchDate, new Date(), accessToken);
        await this.database.addScores(newScores);

        // TODO update score files
    }
}

export const appState = new AppState();
