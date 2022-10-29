//
//  ViewController.swift
//  SeyahatKitabi
//
//  Created by Berke Topcu on 29.10.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        //kullanıcıdan alınacak konumun doğruluk oranı, ne sıklıkla izin alınması gerektiği ve ne zaman konum alınmaya başlanmalı işlemleri burada yapılıyor.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        //Kullanıcan belli bir noktaya uzun basım sonrasında pinleme gerçekleştirilmesi için UITapGestureRecognizer yerine UILongPressGestureRecognizer kullandık. Oluşturduğumuz Gesture Recognizer'ı mapView'a ekledik.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapPinned))
        mapView.addGestureRecognizer(gestureRecognizer)
        //Lokasyona ne kadar süre tıklandıktan sonra pinleme işleminin gerçekleşmesini istediğimiz kısım
        gestureRecognizer.minimumPressDuration = 2
        mapView.isUserInteractionEnabled = true
    }
//Kullanıcıdan enlem ve boylama göre konum almak için

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //lokasyon işlemleri için enlem ve boylam'a özel oluşturulmuş fonksiyonu çağırıp kullandık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi == span
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        //Kullanıcının bulunduğu bölgeyi bulmak için yukarıda oluşturduğumuz enlem ve boylam ve zoomlama seviyesi bilgileriyle kullanıcının anlık bulunduğu noktayı bulduk daha sonrasında bu noktayı mapView üzerinde gösterdik.
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    @objc func mapPinned(gestureRecognizer:UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            //tıklanan noktanın nereden konum almasını istediğimizi belirttik yani "haritadan"
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            //Tıklanan noktanın kordinatları alındı ve sonrasında pin eklenecek
            let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            //Dokunulan bölgenin enlem ve boylam değerlerini scope'da tanımlanan değişkene aktardık bu sayede bu değerleri core data içerisine kaydedebileceğiz.
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            //Pin oluşturuldu
            let annotation = MKPointAnnotation()
            //Oluşturulan pin tıklanan noktaya eklendi
            annotation.coordinate = touchedCoordinates
            annotation.title = nameField.text!
            annotation.subtitle = commentField.text!
            self.mapView.addAnnotation(annotation)
            
        }
    }
    
    //Save button burda çalışıyor
    @IBAction func saveClicked(_ sender: Any) {
        //App Delegate'e ulaştık
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        //Core Data içerisinden Travels Entitysine ulaştık.
        let newTravel = NSEntityDescription.insertNewObject(forEntityName: "Travels", into: context)
        //Entity içerisinde bulunan değerlere kayıt atıyoruz.
        newTravel.setValue(nameField.text!, forKey: "travelName")
        newTravel.setValue(commentField.text!, forKey: "travelComment")
        newTravel.setValue(chosenLatitude, forKey: "latitude")
        newTravel.setValue(chosenLongitude, forKey: "longitude")
        newTravel.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
    }
    
    
}

