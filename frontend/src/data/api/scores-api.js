import {ScoreDto} from "./dtos.js";
import {Creators, Movement, Score, Work} from "../database/models.js";

export class ScoresApi {
    baseUrl = 'http://localhost:7001';

    /**
     * @param changesSince {Date}
     * @param changesUntil {Date}
     * @param authToken {String}
     * @returns {Promise<Score[]>}
     */
    async getScores(changesSince, changesUntil, authToken) {
        const params = new URLSearchParams({
            'Changes-Since': _formatDate(changesSince),
            'Changes-Until': _formatDate(changesUntil),
        });
        const url = `${this.baseUrl}/scores?${params.toString()}`;
        /**
         * @type Response
         */
        const response = await fetch(url, {
            headers: {
                "Authorization": `Bearer ${authToken}`
            }
        });
        if (response.status >= 500) {
            throw `failed to fetch scores (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
        } else if (response.status >= 400) {
            throw `failed to fetch scores: ${response.status} ${response.statusText}: ${await response.text()}`;
        }

        /**
         * @type ScoreDto[]
         */
        const scores = await response.json();

        return scores.map((score) => new Score(
            score.id,
            score.work == null ? null : new Work(score.work.title, score.work.number),
            score.movement == null ? null : new Work(score.movement.title, score.movement.number),
            new Creators(
                score.creators.composers,
                score.creators.lyricists
            ),
            score.languages,
            score.instruments,
            new Date(score.last_changed_at),
            score.tags
        ));
    }

    /**
     * @param scoreId {String}
     * @param authToken {String}
     * @returns {Promise<Score|null>}
     */
    async getScore(scoreId, authToken) {
        const url = `${this.baseUrl}/scores/${scoreId}`;
        /**
         * @type Response
         */
        const response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Accept': 'application/json'
            }
        });
        if (response.status >= 500) {
            throw `failed to fetch score (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
        } else if (response.status >= 400) {
            throw `failed to fetch score: ${response.status} ${response.statusText}: ${await response.text()}`;
        }
        return await response.json();
    }

    /**
     * @param scoreId
     * @param authToken
     * @returns {Promise<String|null>}
     */
    async getScoreMusicxml(scoreId, authToken) {
        const url = `${this.baseUrl}/scores/${scoreId}`;
        /**
         * @type Response
         */
        const response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Accept': 'application/vnd.recordare.musicxml'
            }
        });
        if (response.status >= 500) {
            throw `failed to fetch score musicxml (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
        } else if (response.status >= 400) {
            throw `failed to fetch score musicxml: ${response.status} ${response.statusText}: ${await response.text()}`;
        }
        return await response.text();
    }
}

/**
 * @param date {Date}
 * @returns {string}
 * @private
 */
function _formatDate(date) {
    return date.toISOString()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];
}
