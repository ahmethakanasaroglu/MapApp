//
//  ViewController.swift
//  HaritalarUygulamasi
//
//  Created by Ahmet Hakan Asaroğlu on 11.01.2025.
//

import UIKit
import MapKit
import CoreLocation   // kullanıcının konumunu almak için vs.
import CoreData  // coredata'ya kaydederken


class MapsViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate { // tableView'daki gibi delegate'ı cagırıyoruz.
    
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self // delegate'ı self atıyoruz ki viewController'a ait anlamında
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // istenilen dogrulugu seciyoruz, best'i sectik
        locationManager.requestWhenInUseAuthorization() // kullanıcıdan konum izni alıyoruz, uyg. kullanırkeni sectik
        locationManager.startUpdatingLocation()  // konumu güncellemeye basla dedik
        // info kısmından bilgilendirme de yaptık konum izni için
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3    // minimum kac saniye bassın
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if secilenIsim != "" {
            // core data'dan verileri çek
            if let uuidString = secilenId?.uuidString { // uuid yi string olarak alabiliyorsa
                
                // core data'dan verileri cekicez şimdi aşagıda
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString) // filtreleme yapıyoruz id'ye göre
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        
                        for sonuc in sonuclar as! [NSManagedObject] { // bunu NSManagedObject olarak cast etmek zorundayız
                            
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
        
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubtitle
                                            
                                            // mapView setRegion' a kadar olan kısımda eğer + ile girerse normal lokasyonu göster oldugumuz, eğer önceden kaydedilen bir yere tıklanırsa da oranın lokasyonuna gitmesi için kodu yazdık. yoksa direkt oldugu yeri acıyordu, işaretlenen yer gözükmüyordu.
                                            locationManager.stopUpdatingLocation() // güncellemeyi bırak lokasyonu
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true) // bölgeyi ayarlıyoruz bidaha set edip
                                            
                                            
                                        } // bunlar bitince id için yazmıyorum zaten onu cektik basta gerek yok bidaha
                                    }
                                }
                            } // iç içe yazdık ki bilgilerin hepsi olmak zorunda yoksa hata verir
                          
                            
                            
                            
                        }
                        
                    }
                    
                } catch {
                    print("hata var")
                }



            }
            
        } else {
            // yeni veri eklemeye geldi
            
        }
        
        
        
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } // lokasyon kullanıcının oldugu yer ise bişey yapma dedik. cünkü degilse mesafe cizicez arasında
        
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) // tekrar kullanılabilir annotation olusturuyoruz, id degiskeni olusturduk icine vermek icin
        
        if pinView == nil {  // pinView'i bastan olusturuyoruz
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // ekstra bişey gösterebilir mi buton, resim vs. diye
            pinView?.tintColor = .blue
            
            // simdi pinView'da gösterecegimiz butonu yazıcaz, sağ tarafında lokasyonun mavi bilgi butonu
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)  // detay gösterme butonu tanımladık
            pinView?.rightCalloutAccessoryView = button  // sağda gösterebilir dedik ve gösterecegi şeyi butona esitledik
            
          
            
        } else {
            pinView?.annotation = annotation // bos degilse pinView'in annotationunu annotationa esitle dedik
        }
        
        return pinView
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {  // önceden kaydedilen bir yere girince yani yeni eklemek için tıklamamışsa
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                if let placemarks = placemarkDizisi {  // placemarkDizisi boş degilse demek, opsiyonel olmaktan cıkardık
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])  // dizi gelecegi için placemarkstan ilk elemanını aldık
                        let item = MKMapItem(placemark: yeniPlacemark)  // harita üzerinde kullanılacak bir öge, üstte yeniPlacemark'ı buraya verebilmek için olusturduk
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving] // dict içinde yolu neyle gidecegini verdik, önce modu sectik sonra driving yani arabaya atadık. kullanıcı acınca kendi degisebilir ama ilk acılınca araba ile dedik.
                        item.openInMaps(launchOptions: launchOptions)  // haritada aç ve hangi launchOptions ile oldugunu belirttik
                        
                    }
                    
                }
            }
         
            
            
        }
    } // calloutAccessory'e tıklanınca ne olacağı
    
    
    
    @objc func konumSec(gestureRecognizer: UILongPressGestureRecognizer) { // konumSec'den gestureRecognizere'e ulasıcaz o da üsttekine ulasıcak ve kullanıcının basılı tuttugu yeri algılayacagız.
        if gestureRecognizer.state == .began {    // eğer durumu baslamışsa diyoruz.
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)  // mapView'a dokunulacagı icin
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView) // dokunulan noktayı koordinata ceviriyoruz
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            
            mapView.addAnnotation(annotation)
            
            
        }
        
    }
    

    // üst tarafta aldıgımız konum sonrasında ne yapacagımızı bu fonksiyonda belirtiyoruz.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // print(locations[0].coordinate.latitude)
        // print(locations[0].coordinate.longitude)
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // verilen deger daha küçükse zoom artar
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        } // eğer kullanıcı bir yer secmediyse kalsın bu ama eklenen bir yere gidecekse isim bos degilse baska olcak
        
        
    }
    
    
    @IBAction func kaydetTiklandi(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        // üstteki 5 degeri de coredata daki kaydetmis olacagız. aşağıdaki context.save() ile
        
        do {
            try context.save()
            print("kayıt edildi")
        } catch {
            print("hata var")
        }
        
        
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil) // kayıt eklenince listVC'a dönmesi içn olan asamadayız. eklenme notification'u verdik
        navigationController?.popViewController(animated: true)  // bi önceki VC'a dönmesi icin
        
        
        
        
        
        
        
        
    }
    
    

}

