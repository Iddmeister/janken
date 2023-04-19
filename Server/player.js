class Player {

    constructor(username, client) {
        this.client = client
        this.username = username
        this.team = null
        this.game = null
    }

    clientRequest(data) {

        if (this.team) {

            switch (data.type) {

                case "leaveTeam":

                    this.team.removePlayer(this.username)
                    
                    this.client.sendData({type:"leftTeam"})

                    break;

                case "changeType":

                    this.team.playerChangeType(this.username, data.newType)

                    break;

                case "changeReady":

                    this.team.playerChangeReady(this.username, data.ready)
                    
                    break;
            }
        }
    }
}

module.exports = {Player}