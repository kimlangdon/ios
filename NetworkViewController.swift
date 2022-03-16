//
//  NetworkViewController.swift
//  showSkills
//
//  Created by Kim on 1/20/22.
//
//  How do I get the forecast?
//  Forecasts are divided into 2.5km grids. Each NWS office is responsible for a section of the grid.
//  The API endpoint for the forecast at a specific grid is:
//
//  https://api.weather.gov/gridpoints/{office}/{grid X},{grid Y}/forecast
//  For example: https://api.weather.gov/gridpoints/TOP/31,80/forecast
//
//  If you do not know the grid that correlates to your location, you can use
//  the /points endpoint to retrieve the  exact grid endpoint by coordinates:
//
//  https://api.weather.gov/points/{latitude},{longitude}
//  For example: https://api.weather.gov/points/39.7456,-97.0892
//
//  This will return the grid endpoint in the "forecast" property.
//  Applications may cache the grid for a location to improve latency and reduce the additional lookup request.
//  This endpoint also tells the application where to find information for issuing office,
//  observation stations, and zones.

import Foundation
import UIKit
import CoreLocation
import MapKit

class NetworkViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
  
  // weather office
  struct WeatherOffice : Codable {
    let properties: wo_properties
  }
  
  struct wo_properties: Codable {
    let gridId : String
    let gridX: Int
    let gridY: Int
    let relativeLocation: rl_properties
  }
  
  struct rl_properties : Codable {
    let properties: citystate
  }
  
  struct citystate : Codable {
    let city : String
    let state : String
  }
  
  // forecast
  struct Forecast : Codable {
    let properties: properties
  }
  
  struct properties: Codable {
    let updated : String
    let periods : [periods]
  }
  
  struct periods: Codable {
    let number : Int
    let name : String
    let temperature : Int
    let temperatureUnit : String
    let windSpeed : String
    let windDirection : String
    let icon : String
    let shortForecast : String
    let detailedForecast : String
    
  }
  
  var locationManager:CLLocationManager!
  var mapView:MKMapView!
  
  @IBOutlet weak var imgWeatherIcon: UIImageView!
  @IBOutlet weak var imgWeatherLaterIcon: UIImageView!
  
  @IBOutlet weak var lblForecast: UILabel!
  @IBOutlet weak var lblTemp: UILabel!
  @IBOutlet weak var lblLaterForecast: UILabel!
  
  @IBOutlet weak var lblCityState: UILabel!
  @IBOutlet weak var lblTempLater: UILabel!
  @IBOutlet weak var lblForecastNow: UILabel!
  
  override func viewDidLoad() {
    lblTemp.text = ""
    lblForecast.text = ""
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    createMapView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    determineCurrentLocation()
  }
  
  func showAlertMessageOK (message: String) {
    let alertController = UIAlertController(title: "Error", message: message, preferredStyle:UIAlertController.Style.alert)
    
    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                              { action -> Void in
      // user has selected ok
      
    })
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func determineCurrentLocation()
  {
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    
    if CLLocationManager.locationServicesEnabled() {
      //locationManager.startUpdatingHeading()
      locationManager.startUpdatingLocation()
    }
  }
  
  
  func createMapView()
  {
    mapView = MKMapView()
    
    let leftMargin:CGFloat = 10
    let topMargin:CGFloat = 20
    let mapWidth:CGFloat = view.frame.size.width-20
    let mapHeight:CGFloat = 300
    
    mapView.frame = CGRect(x: leftMargin, y: topMargin, width: mapWidth, height: mapHeight)
    
    mapView.mapType = MKMapType.standard
    mapView.isZoomEnabled = true
    mapView.isScrollEnabled = true
    let gestureRecognizer = UITapGestureRecognizer(
      target: self, action:#selector(handleTap))
    gestureRecognizer.delegate = self
    gestureRecognizer.numberOfTapsRequired = 3
    mapView.addGestureRecognizer(gestureRecognizer)
    
    view.addSubview(mapView)
  }
  
  @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
    
    let location = gestureRecognizer.location(in: mapView)
    let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
    
    // Add annotation:
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    getWeatherByLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    mapView.addAnnotation(annotation)
  }
  
  private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let userLocation:CLLocation = locations[0] as CLLocation
    
    // Call stopUpdatingLocation() to stop listening for location updates,
    // other wise this function will be called every time when user location changes.
    //manager.stopUpdatingLocation()
    
    let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    mapView.setRegion(region, animated: true)
    
    // Drop a pin at user's Current Location
    let myAnnotation: MKPointAnnotation = MKPointAnnotation()
    myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude);
    myAnnotation.title = "Current location"
    mapView.addAnnotation(myAnnotation)
  }
  
  func getWeatherByLocation (latitude: Double ,longitude: Double) {
    //https://api.weather.gov/points/39.7456,-97.0892
    if let url = URL(string: "https://api.weather.gov/points/\(latitude),\(longitude)") {
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let response = response as? HTTPURLResponse,
              error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                DispatchQueue.main.async {
                  self.showAlertMessageOK(message: "Unknow error")
                }
                return
              }
        
        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
          print("statusCode should be 2xx, but is \(response.statusCode)")
          print("response = \(response)")
          DispatchQueue.main.async {
            self.showAlertMessageOK(message: "Weather forecast only available in United States")
          }
          return
        }
        DispatchQueue.main.async {
          //debug to look at string
          //let responseString = String(data: data, encoding: .utf8)
          //print("responseString = \(responseString)")
          let decoder = JSONDecoder()
          do {
            let weatherOffice = try decoder.decode(WeatherOffice.self, from: data)
            print(weatherOffice)
            self.lblCityState.text = "\(weatherOffice.properties.relativeLocation.properties.city), \(weatherOffice.properties.relativeLocation.properties.state)"
            if let url = URL(string: "https://api.weather.gov/gridpoints/\(weatherOffice.properties.gridId)/\(weatherOffice.properties.gridX),\(weatherOffice.properties.gridY)/forecast") {
              var request = URLRequest(url: url)
              request.httpMethod = "GET"
              
              let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let response = response as? HTTPURLResponse,
                      error == nil else {                                              // check for fundamental networking error
                        print("error", error ?? "Unknown error")
                        return
                      }
                
                guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                  print("statusCode should be 2xx, but is \(response.statusCode)")
                  print("response = \(response)")
                  return
                }
                DispatchQueue.main.async {
                  //degug
                  //let responseString = String(data: data, encoding: .utf8)
                  // print("responseString = \(responseString)")
                  let decoder = JSONDecoder()
                  do {
                    let container = try decoder.decode(Forecast.self, from: data)
                    print(container)
                    let curRecTemp = container.properties.periods[0]
                    
                    let iconUrl = container.properties.periods[0].icon
                    self.imgWeatherIcon.setImageFrom(iconUrl, completion: {print("hellow word")})
                    let curTemp = String(curRecTemp.temperature) + "°" + " " + curRecTemp.temperatureUnit
                    self.lblTemp.text = curTemp
                    
                    
                    self.lblForecastNow.text = curRecTemp.name
                    self.lblForecast.text = curRecTemp.detailedForecast
                    let curRecLater = container.properties.periods[1]
                    let iconURLLater = curRecLater.icon
                    let urlLater = URL(string: iconURLLater)
                    let imageLaterData = try Data(contentsOf: urlLater!)
                    self.imgWeatherLaterIcon.image = UIImage(data: imageLaterData)
                    self.lblLaterForecast.text = curRecLater.name
                    let tempLater = String(curRecLater.temperature) + "°" + " " + curRecLater.temperatureUnit
                    self.lblTempLater.text = tempLater
                  }
                  catch {
                    
                  }
                }
                
                
              }
              
              task.resume()
            }
          }
          catch {
            
          }
        }
        
        
      }
      
      task.resume()
    }
  }
  
  func getBoiseWeather () {
    if let url = URL(string: "https://api.weather.gov/gridpoints/BOI/131,83/forecast") {
      var request = URLRequest(url: url)
      //request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      request.httpMethod = "GET"
      //  let parameters: [String: Any] = [
      //      "id": 13,
      //      "name": "Jack & Jill"
      //  ]
      //request.httpBody = parameters.percentEncoded()
      
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let response = response as? HTTPURLResponse,
              error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
              }
        
        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
          print("statusCode should be 2xx, but is \(response.statusCode)")
          print("response = \(response)")
          return
        }
        DispatchQueue.main.async {
          //let responseString = String(data: data, encoding: .utf8)
          // print("responseString = \(responseString)")
          let decoder = JSONDecoder()
          do {
            let container = try decoder.decode(Forecast.self, from: data)
            print(container)
            let curRecTemp = container.properties.periods[0]
            
            let iconUrl = container.properties.periods[0].icon
            //            let url = URL(string: iconUrl)
            //            let iconImageData = try Data(contentsOf: url!)
            //            //loadingView.removeFromSuperview()
            //            //self.imgWeatherIcon.image =
            //            self.imgWeatherIcon.layer.borderWidth = 2
            //            self.imgWeatherIcon.layer.borderColor = UIColor.red.cgColor
            //            self.imgWeatherIcon.image = UIImage(data: iconImageData)
            //self.imgWeatherIcon.startAnimating()
            self.imgWeatherIcon.setImageFrom(iconUrl, completion: {print("hellow word")})
            let curTemp = String(curRecTemp.temperature) + "°" + " " + curRecTemp.temperatureUnit
            self.lblTemp.text = curTemp
            
            
            self.lblForecastNow.text = curRecTemp.name
            self.lblForecast.text = curRecTemp.detailedForecast
            let curRecLater = container.properties.periods[1]
            let iconURLLater = curRecLater.icon
            let urlLater = URL(string: iconURLLater)
            let imageLaterData = try Data(contentsOf: urlLater!)
            self.imgWeatherLaterIcon.image = UIImage(data: imageLaterData)
            // not used yet.. let laterTemp = String(curRecLater.temperature) + "°" + " " + curRecLater.temperatureUnit
            self.lblLaterForecast.text = curRecLater.name
            let tempLater = String(curRecLater.temperature) + "°" + " " + curRecLater.temperatureUnit
            self.lblTempLater.text = tempLater
          }
          catch {
            
          }
        }
        
        
      }
      
      task.resume()
    }
  }
  
  
}

extension UIImageView {
  
  //// Returns activity indicator view centrally aligned inside the UIImageView
  private var activityIndicator: UIActivityIndicatorView {
    let activityIndicator = UIActivityIndicatorView()
    activityIndicator.hidesWhenStopped = true
    activityIndicator.color = UIColor.black
    self.addSubview(activityIndicator)
    
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    
    let centerX = NSLayoutConstraint(item: self,
                                     attribute: .centerX,
                                     relatedBy: .equal,
                                     toItem: activityIndicator,
                                     attribute: .centerX,
                                     multiplier: 1,
                                     constant: 0)
    let centerY = NSLayoutConstraint(item: self,
                                     attribute: .centerY,
                                     relatedBy: .equal,
                                     toItem: activityIndicator,
                                     attribute: .centerY,
                                     multiplier: 1,
                                     constant: 0)
    self.addConstraints([centerX, centerY])
    return activityIndicator
  }
  
  /// Asynchronous downloading and setting the image from the provided urlString
  func setImageFrom(_ urlString: String, completion: (() -> Void)? = nil) {
    guard let url = URL(string: urlString) else { return }
    
    let session = URLSession(configuration: .default)
    let activityIndicator = self.activityIndicator
    
    DispatchQueue.main.async {
      activityIndicator.startAnimating()
    }
    
    let downloadImageTask = session.dataTask(with: url) { (data, response, error) in
      if let error = error {
        print(error.localizedDescription)
      } else {
        if let imageData = data {
          DispatchQueue.main.async {[weak self] in
            var image = UIImage(data: imageData)
            self?.image = nil
            self?.image = image
            image = nil
            completion?()
          }
        }
      }
      DispatchQueue.main.async {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
      }
      session.finishTasksAndInvalidate()
    }
    downloadImageTask.resume()
  }
}
