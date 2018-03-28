/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import MapKit

class FollowViewController: UIViewController {

    // MARK: Variables

    let session: TrackingSession
    var socket: WebSocket?

    // MARK: View Attributes

    let annotation = MKPointAnnotation()
    @IBOutlet weak var mapView: MKMapView!

    // MARK: Initializers

    init(session: TrackingSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.addAnnotation(annotation)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSocket()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        socket?.close()
    }

    // MARK: Updates

    func startSocket() {
        let ws = WebSocket("ws://\(host)/listen/\(session.id)")

        ws.event.close = { [weak self] code, reason, clean in
            self?.navigationController?.popToRootViewController(animated: true)
        }

        ws.event.message = { [weak self] message in
            guard let bytes = message as? [UInt8] else { return }
            let data = Data(bytes: bytes)
            let decoder = JSONDecoder()
            do {
                let location = try decoder.decode(
                    Location.self,
                    from: data
                )
                self?.focusMapView(location: location)
            } catch {
                print("Error decoding location: \(error)")
            }
        }
    }

    func focusMapView(location: Location) {
        let mapCenter = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        annotation.coordinate = mapCenter
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(mapCenter, span)
        mapView.region = region
    }
}
