import {AuthorizationService} from "./data/auth.js";
import {apiConfig, authConfig} from "./config.js";
import {ScoresApi} from "./data/scores-api.js";
import {Database} from "./data/database.js";

export const database = new Database();

export const authService = new AuthorizationService(authConfig);

export const api = new ScoresApi(apiConfig);
