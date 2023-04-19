class Team {

    constructor(code, queue, deleteCallback) {
        this.code = code
        this.players = {}
        this.full = false
        this.inQueue = false
        this.queue = queue
        this.deleteCallback = deleteCallback
    }

    sendIndividualData(dataFunction) {
        for (let player of Object.keys(this.players)) {
            let data = dataFunction(this.players[player].object)
            if (data) {
                this.players[player].object.client.sendData(data)
            }
        }
    }

    sendTeamData(data) {
        for (let player of Object.keys(this.players)) {
            this.players[player].object.client.sendData(data)
        }
    }

    joinQueue() {
        this.inQueue = true
        this.queue.addTeam(this)    
    }

    leaveQueue() {
        if (this.inQueue) {
            this.queue.removeTeam(this.code)
            this.inQueue = false
        }
    }

    playerChangeType(player, type) {

        if (this.players[player].ready) return

        if (this.players[player]) {
            this.players[player].type = type
            this.sendTeamData({type:"playerChangedType", player:player, newType:type})
        }
    }

    playerChangeReady(player, ready) {

        if (!this.players[player]) return

        this.players[player].ready = ready

        if (ready) {

            let types = {0:false, 1:false, 2:false}
            let allGood = true

            for (let p of Object.keys(this.players))  {
                if (types[this.players[p].type]) {
                    this.players[player].ready = false
                    allGood = false
                    this.players[player].object.client.sendData({type:"typeTakenError"})
                    break
                } else {
                    types[this.players[p].type] = true
                }
            }

            if (allGood) this.joinQueue()

        } else {
            this.leaveQueue()
        }
        
        this.sendTeamData({type:"playerChangedReady", player:player, ready:this.players[player].ready})


    }

    deleteTeam() {
        this.deleteCallback()
    }

    removePlayer(username) {

        if (!Object.keys(this.players).includes(username)) {
            return false
        }

        this.full = false

        if (this.players[username]) {
            this.players[username].team = null
            delete this.players[username]
        }
        if (Object.keys(this.players).length <= 0) {
            this.deleteTeam()
        }

        this.sendTeamData({type:"playerLeft", player:username})

    }

    addPlayer(newPlayer) {

        if (Object.keys(this.players).includes(newPlayer.username)) {
            return false
        }

        if (this.full) {
            return false
        }

        newPlayer.client.sendData({type:"joinedTeam", code:this.code})

        for (let player of Object.keys(this.players)) {
            let playerObj = this.players[player]
            playerObj.object.client.sendData({type:"playerJoined", player:newPlayer.username, ready:false, newType:0})
            newPlayer.client.sendData({type:"playerJoined", player:player, ready:playerObj.ready, newType:playerObj.type})
        }

        this.players[newPlayer.username] = {object:newPlayer, ready:false, type:0}
        
        newPlayer.team = this

        newPlayer.client.sendData({type:"playerJoined", player:newPlayer.username, ready:false, newType:0})

        if (Object.keys(this.players).length >= 3) {
            this.full = true
        }
    }
}


module.exports = {Team}