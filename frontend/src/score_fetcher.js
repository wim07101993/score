onmessage = async (event) => {
    console.log(event)
    console.log("Start fetching scores!");
    const scores = await fetchScores();
    console.log("Done fetching scores");
    scores.forEach(score => {
        console.log(score.id);
        console.log(score);
    })
}

/**
 * @returns {Promise<Score[]>}
 */
async function fetchScores() {
    const url = "http://localhost:7001/scores"
    try {
        const response = await fetch(url);
        if (!response.ok) {
            console.error(`Response status: ${response.status}, ${await response.text()}`)
            return [];
        }

        const json = await response.json();
        console.log(json)
        return json;
    }catch (error) {
        console.error(error.message)
        return []
    }
}

class Score {
    /**
     * @param {string} id
     * @param {Work} work
     * @param {Movement} movement
     * @param {string[]} creators
     * @param {string[]} languages
     * @param {string[]} instruments
     * @param {Date} last_changed_timestamp
     * @param {string[]} tags
     */
    constructor(id,
                work,
                movement,
                creators,
                languages,
                instruments,
                last_changed_timestamp,
                tags) {
        this.id = id;
        this.work = work;
        this.movement = movement;
        this.creators = creators;
        this.languages = languages;
        this.instruments = instruments;
        this.last_changed_timestamp = last_changed_timestamp;
        this.tags = tags;
    }
}

class Movement {
    /**
     * @param {string} title
     * @param {bigint} number
     */
    constructor(title, number) {
        this.title = title;
        this.number = number;
    }
}

class Work {
    /**
     * @param {string} title
     * @param {bigint} number
     */
    constructor(title, number) {
        this.title = title;
        this.number = number;
    }
}