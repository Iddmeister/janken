var {Team} = require("./team")


class Queue {

    constructor(delay=1000, gameFoundCallback) {
        this.queue = []
        setInterval(() => {

            while (Object.keys(this.queue).length > 1) {
                let team1 = Object.keys(this.queue)[0]
                let team2 = Object.keys(this.queue)[1]
                gameFoundCallback(this.queue[team1].team, this.queue[team2].team)
                this.queue[team1].team.leaveQueue()
                this.queue[team2].team.leaveQueue()

            }

            if (Object.keys(this.queue).length == 1) {
                if (Object.keys(this.queue[Object.keys(this.queue)[0]].team.players)[0] == "solo") {
                    gameFoundCallback(this.queue[Object.keys(this.queue)[0]].team, new Team("hmmm"))
                }
            }
            

        }, delay)
    }

    addTeam(team) {

        if (!this.queue[team.code]) this.queue[team.code] = {team:team, time:0}

    }

    removeTeam(code) {
        if (this.queue[code]) delete this.queue[code]
    }
}

module.exports = {Queue}