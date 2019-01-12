//
//  Channel.swift
//  tempohs
//
//  Created by Soltis, Matthew on 1/8/19.
//  Copyright © 2019 Soltis, Matthew. All rights reserved.
//

import UIKit

class Channel {
    //MARK: Properties
    var name:String //User-given name for channel.  may have character restrictions for roomName
    var rowInTableView:Int //unique identifer amongst channels since tableview is indexed
    var roomName:String //a channel in the app corresponds to a room in opentok.  roomName must be URL compliant and may necessitate some character restrictsions in name.  URLify the "name" and append rowInTableView to guarantee uniqueness
    var apiKey:String
    var sessionID:String //OpenTok session ID, one for each room (channel)
    var token:String //OpenTok token unique to that user and steeam for a session (I think)
    var connectionStatus:String  //display in tableview subtitle based on connection.  "Not Connected" or "Connected"
    
    //MARK: Initialization
    init(name:String, rowInTableView:Int, roomName:String, apiKey:String, sessionID:String, token:String, connectionStatus:String) {
        //Initialize stored propoerties
        self.name = name
        self.rowInTableView = rowInTableView
        self.roomName = roomName
        self.apiKey = apiKey
        self.sessionID = sessionID
        self.token = token
        self.connectionStatus = connectionStatus
    }
    
    convenience init() {
        self.init(name: "", rowInTableView: 0, roomName: "", apiKey: "", sessionID: "", token: "", connectionStatus: "Not Connected")
    }
}
