//
//  ViewController.swift
//  tempohs
//
//  Created by Soltis, Matthew on 12/31/18.
//  Copyright © 2018 Soltis, Matthew. All rights reserved.
//

import UIKit
import OpenTok
import Alamofire

var url:String = "http://pure-coast-92727.herokuapp.com"

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // OpenTok state variables
    var session: OTSession?
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    // Model state variable
    var myChannels = [Channel]()
    //data eventually comeing from administration
    var numChannels = 4
    var channelNames = ["Offense 1", "Offense 2", "Defense 1", "Defense 2"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //populate channel models manually for now
        for i in 0...(numChannels - 1) {
            let channel = Channel()
            channel.rowInTableView = i
            channel.name = channelNames[i]
            let uniqueName = channelNames[i] + String(i)
            channel.roomName = uniqueName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            self.myChannels.append(channel)
        }
        print("ViewDidLoad")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return numChannels
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "datacell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = myChannels[indexPath.row].name
        cell.detailTextLabel?.text = myChannels[indexPath.row].connectionStatus
        //cell.imageView?.image = UIImage(named: channel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Channels:"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Did Select channel: " + self.myChannels[indexPath.row].name)
       if self.myChannels[indexPath.row].sessionID.isEmpty {
            //create room
            createAnOpenTokSession(index: indexPath.row)
            }
       else {
            //connect to existing room
            connectToAnOpenTokSession(index: indexPath.row)
        }


    }
    
    func createAnOpenTokSession(index: Int) {
        var JSON = [String:String]()
        
        //Get apikey, sessionid and token from server
        Alamofire.request(url + "/room/:" + self.myChannels[index].roomName)
            .responseJSON { response in
                guard response.result.isSuccess,
                    let value = response.result.value else {
                        print("Error while fetching tags: \(String(describing: response.result.error))")
                        return
                }
                print("Got keys")
                //assign keys to model state variable
                JSON = value as! [String:String]
                self.myChannels[index].apiKey = JSON["apiKey"]!
                self.myChannels[index].sessionID = JSON["sessionId"]!
                self.myChannels[index].token = JSON["token"]!
                // create a new session in opentok
                self.session = OTSession(apiKey: self.myChannels[index].apiKey, sessionId: self.myChannels[index].sessionID, delegate: self)
                print("Session Created")
                //go connect to that new session
                self.connectToAnOpenTokSession(index: index)

        }
    }

    
    func connectToAnOpenTokSession(index: Int) {
        // called when you re-enter a room
        var error: OTError?
        self.session?.connect(withToken: self.myChannels[index].token, error: &error)
        if error != nil {
            print(error!)
            print("Yep")
        }
        print("Session Connected")
    }

}

// MARK: - OTSessionDelegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("The client connected to the OpenTok session.")

        let settings = OTPublisherSettings()
        settings.videoTrack = false
        settings.name = UIDevice.current.name
        guard let publisher = OTPublisher(delegate: self, settings: settings) else {
            return
        }

        var error: OTError?
        session.publish(publisher, error: &error)
        guard error == nil else {
            print(error!)
            return
        }

        guard let publisherView = publisher.view else {
            return
        }
        let screenBounds = UIScreen.main.bounds
        publisherView.frame = CGRect(x: screenBounds.width - 150 - 20, y: screenBounds.height - 150 - 20, width: 150, height: 150)
        view.addSubview(publisherView)
    }

    func sessionDidDisconnect(_ session: OTSession) {
        print("The client disconnected from the OpenTok session.")
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("The client failed to connect to the OpenTok session: \(error).")
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        subscriber = OTSubscriber(stream: stream, delegate: self)
        guard let subscriber = subscriber else {
            return
        }

        var error: OTError?
        session.subscribe(subscriber, error: &error)
        guard error == nil else {
            print(error!)
            return
        }

        guard let subscriberView = subscriber.view else {
            return
        }
        subscriberView.frame = UIScreen.main.bounds
        view.insertSubview(subscriberView, at: 0)
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    }
}

// MARK: - OTPublisherDelegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("The publisher failed: \(error)")
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension ViewController: OTSubscriberDelegate {
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("The subscriber did connect to the stream.")
    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("The subscriber failed to connect to the stream.")
    }
}
