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

//var url:String = "http://10.0.0.181:8080"
//var url:String = "http://10.121.15.37:8080"
var url:String = "http://pure-coast-92727.herokuapp.com"
struct OpenTokData {
    var name: String
    var kApiKey: String
    var kSessionId: String
    var kToken: String
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var session: OTSession?
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    var channels = ["Offense 1", "Offense 2", "Defense 1", "Defense 2"]
    var rooms: [OpenTokData] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "datacell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // Configure the cell...
        let channel = channels[indexPath.row]
        cell.textLabel?.text = channel
        cell.detailTextLabel?.text = "not connected"
        //cell.imageView?.image = UIImage(named: channel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Channels:"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = channels[indexPath.row]
        print("Did Select channel: " + name)
        if !rooms.isEmpty && rooms.contains(where: {$0.name == name}) {
            print("room exists")
        } else {
            print("New Room")
            let URLName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            connectToAnOpenTokSession(roomName: URLName!)
        }
    }
    
    func connectToAnOpenTokSession(roomName: String) {
        var JSON = [String:String]()
        var key: String = ""
        var id: String = ""
        var token: String = ""
        print("Connect to OpenTokSession")
        
        Alamofire.request(url + "/room/:" + roomName)
            // 2
            .responseJSON { response in
                guard response.result.isSuccess,
                    let value = response.result.value else {
                        print("Error while fetching tags: \(String(describing: response.result.error))")
                        return
                }
                print("Got keys")
                JSON = value as! [String:String]
                key = JSON["apiKey"]!
                id = JSON["sessionId"]!
                token = JSON["token"]!
                self.rooms.append(OpenTokData(name: roomName, kApiKey: key, kSessionId: id, kToken: token))
                self.session = OTSession(apiKey: key, sessionId: id, delegate: self)
                print("Session Created")
                var error: OTError?
                self.session?.connect(withToken: token, error: &error)
                if error != nil {
                    print(error!)
                }
                print("Session Connected")
        }
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
