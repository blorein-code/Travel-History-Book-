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
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var chosenName = ""
    var chosenID : UUID?
    var annotationName = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
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
        
        //Table View üzerinden seçilen kayıtlı verinin nameField bölümü, kaydedilirken doldurulmuşsa aşağıdaki adımları gerçekleştiriyoruz.
        if chosenName != "" {
            //App delegate'e ulaştık Core Data üzerinden veri çekme işlemleri için
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //Context'imizi yazdık
            let context = appDelegate.persistentContainer.viewContext
            //fetchRequest işleminin nerden yapılacağını (CoreData üzerinde Travels olarak oluşturduğumuz Entity) ve Bize ne tür bir veri döndüreceğini belirttik.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Travels")
            fetchRequest.returnsObjectsAsFaults = false
            // Bir idString yapısı tanımladık ve uuidstring olacağını söyledik
            let idString = chosenID!.uuidString
            //fetchRequest işleminde neye göre veriyi getireceğimizi belirttik (Yani UUID olarak oluşturduğumuz objeleri UUIDString üzerinden çekiyoruz)
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            //Daha sonrasında viewContext'e ulaşmak ve fetch ile veri çekme işleminin konumunu belirtmek için ; context.fetch yapımıza Gelecek verinin nereden geleceği ve nasıl geleceğini belirttik.
            do {
                let results =  try context.fetch(fetchRequest)
                //Eğer veri geliyorsa ve gelen verilerin CoreData üzerine Eklediğimiz Travels Entity'si üzerindeki karşılıkları ile girilen verilerin türlerinin eşleşmediği durum için if let yapısı ile projeyi sağlama aldık.
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "travelName") as? String {
                            annotationName = name
                        }
                        if let comment = result.value(forKey: "travelComment") as? String {
                            annotationComment = comment
                        }
                        if let latitude = result.value(forKey: "latitude") as? Double {
                            annotationLatitude = latitude
                        }
                        if let longitude = result.value(forKey: "longitude") as? Double {
                            annotationLongitude = longitude
                        }
                        // Bir Annotation oluşturduk (Pinleme işareti), Kullanıcı TableView üzerinden kaydettiği Adresleri tekrar görmek istediği zaman bu pinleme işlemi haritada çıkabilsin diye.
                        
                        let annotation = MKPointAnnotation()
                        //Annotation'a kullanıcının girdiği name ve commentlerin TableView'dan gidildiğinde de gösterilmesini sağladık
                        annotation.title = annotationName
                        annotation.subtitle = annotationComment
                        //Veriler harita üzerine geldiğinde kaydedilen konumun da doğru gelmesi için enlem ve boylam değerlerimizi de Pinleme üzerine aktardık.
                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                        annotation.coordinate = coordinate
                            //Table View'dan tıklanınca gidilen Map'e annotation'ı verdik
                        mapView.addAnnotation(annotation)
                        //Kullanıcının girdiği name ve comment bölümlerini Pin üzerinde gösterdik.
                        nameField.text = annotationName
                        commentField.text = annotationComment
                        locationManager.stopUpdatingLocation()
                        //Yukarıda bir coordinate oluşturduğumu için yine aynısını kullanabileceğiz bu yüzden bir span oluşturuyoruz. Ardından bu span'i ve yukarıda bulunan coordinate'i kullanarak region'dan bulunulan bölgeyi belirtiyoruz. Daha sonrasında bu bölgeyi mapView'da gösteriyoruz Bu sayede kullanıcının kaydettiği Konum tam olarak haritada gözükmüş oluyor.
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                        saveButton.isHidden = true
                    }
                }
            } catch {
                print("error")
            }
                    }
        else {
            // Add new content
        }
    }
//Kullanıcıdan enlem ve boylama göre konum almak için

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Gelen veride kaydedilen bölgenin ismi yoksa kullanıcının konumunu tekrar güncellemesini istemediğimiz için böyle bir önlem aldık. Eğer konumumn ismi bulunmuyorsa kullanıcının yeni konumunu göstermeyecek.
        if chosenName == "" {
        //lokasyon işlemleri için enlem ve boylam'a özel oluşturulmuş fonksiyonu çağırıp kullandık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi == span
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        //Kullanıcının bulunduğu bölgeyi bulmak için yukarıda oluşturduğumuz enlem ve boylam ve zoomlama seviyesi bilgileriyle kullanıcının anlık bulunduğu noktayı bulduk daha sonrasında bu noktayı mapView üzerinde gösterdik.
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
        
    }
    //Kullanıcı belli bir yeri pinledikten daha sonra bu konuma yol tarifi alabilmesi için pinleme işaretinin yanına bir buton oluşturuyoruz. Daha sonrasında butona basan kullanıcının mevcut konumunu alıp, bu kayıtlı konuma yol tarifini göstereceğiz.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        //tekrar kullanmak için bir id tanımladık
        var reuseId = "myAnnotation"
        //bir pinView oluşturduk, tekrar kullanılabilir olması için bunun bir MKPinAnnotationView olduğunu söyledik ve bir pinView döndürdük.
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //Callout: Bir baloncuk içerisinde ekstra bilgi gösterilebilen alan.
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            //Detay butonu oluşturduk
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            //Oluşturduğumuz butonu sağ tarafta gösterdik.
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    //Pin'e tıklandıktan sonra çıkan information butonuna yaptırılmak istenenlerin yazıldığı fonksiyon.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenName != "" {
            //istenilen konum tekrar oluşturuldu.
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            //mevcut konum ile gidilecek konum arasında bağlantı kurmak için gerekli hazır fonksiyon
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //placemarks nil değilse kontrolü yapmak için if let yapısı kurduk.
                //placemark objesini reverse geocode location ile alıp kullanabiliyoruz.
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        //Navigasyonu açabilmek için bir tane MapItem tanımladık.
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationName
                        //Bu mapItem'ın hangi modu kullanmasını istediğimizi söyledik DirectionModeDriving (Arabayla)
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
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
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    
}

