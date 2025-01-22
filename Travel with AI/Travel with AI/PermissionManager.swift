//
//  PermissionManager.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 22/01/2025.
//

import Foundation
import AVFoundation
import CoreLocation

enum PermissionType {
    case location
    case camera
}

class PermissionManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var locationCompletion: ((Bool) -> Void)?

    func requestPermission(for type: PermissionType, completion: @escaping (Bool) -> Void) {
        switch type {
        case .location:
            requestLocationPermission(completion: completion)
        case .camera:
            requestCameraPermission(completion: completion)
        }
    }

    private func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            completion(true)
        case .notDetermined:
            locationCompletion = completion
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Ignore the 'undefined' or 'notDetermined' state as it is temporary.
        if status == .notDetermined { return }

        if let completion = locationCompletion {
            let granted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            locationCompletion = nil
            completion(granted)
        }
    }
}
