//
//  Constants.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//
import Foundation

struct Constants {
    // Production URL
     static let baseURL = "https://dam-4sim2.onrender.com"
    
    // Local development - Use your computer's IP address (find with: ifconfig | grep "inet ")
   // static let baseURL = "http://192.168.1.138:10000"  // ⚠️ UPDATE THIS WITH YOUR LOCAL IP
    
    // Localhost doesn't work on iOS Simulator or physical device - use IP address instead
    // static let baseURL = "http://localhost:10000"  // ❌ Won't work on iOS
    
    static let flaskURL = "https://flask-ai-api-1ynk.onrender.com/api"
    static let openRouteApiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjI1NDQyOWQwY2JhNjQ5ZmViYjEzNzlkNDAwZjNjZDgyIiwiaCI6Im11cm11cjY0In0="
}
